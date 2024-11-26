param(
   [string]$environmentName = "dev",
   [string]$sqlServerDbPassword = "p@ssW0rd",
   [string]$sqlServerDebeziumUser = "debezium-usr",
   [string]$sqlServerDebeziumPassword = "p@ssW0rd"
)

function Ensure-SqlServerModule {
   if (-not (Get-Module -ListAvailable -Name SqlServer)) {
      Write-Host "SqlServer module not found. Installing..."
      Install-Module -Name SqlServer -Force -Scope CurrentUser
   } else {
      Write-Host "SqlServer module is already installed."
   }
}

function Get-MyIp {
   return (Invoke-RestMethod http://ipinfo.io/json).ip
}

function Get-FirewallIps {
   param (
      [Parameter(Mandatory=$true)]
      [object]$deployOutput
   )
   $myIp = Get-MyIp
   return @($myIp) + $deployOutput.outputs.debeziumOutboundIps.value
}

function Get-CurrentFirewallRules {
   param (
      [Parameter(Mandatory=$true)]
      [string]$sqlServerId
   )
   return az sql server firewall-rule list --ids $sqlServerId --query "[].{id:id, name:name, startIpAddress:startIpAddress, endIpAddress:endIpAddress}" -o json | ConvertFrom-Json
}

function Remove-UnwantedSqlFirewallRules {
   param (
      [Parameter(Mandatory=$true)]
      [array]$currentFirewallRules,
      [Parameter(Mandatory=$true)]
      [array]$fireWallIps
   )
   $currentFirewallRules | ForEach-Object {
      if ($fireWallIps -notcontains $_.startIpAddress) {
         Write-Host "Deleting firewall rule: $($_.name)"
         az sql server firewall-rule delete --ids $_.id
      }
   }
}

function Add-MissingSqlFirewallRules {
   param (
      [Parameter(Mandatory=$true)]
      [array]$missingFirewallIps,
      [Parameter(Mandatory=$true)]
      [object]$deployOutput
   )
   $missingCount = $missingFirewallIps.Count
   $missingFirewallIps | ForEach-Object -Begin { $i = 0 } -Process {
      $i++
      Write-Host "Creating firewall rule for IP: $_ ($i of $missingCount)"
      az sql server firewall-rule create -g $deployOutput.outputs.resourceGroupName.value -s $deployOutput.outputs.sqlServerName.value -n "ClientIPAddress_$($_)_$($_)" --start-ip-address $_ --end-ip-address $_ -o none
   }
}

function Deploy-SqlFirewallRules {
   param (
      [Parameter(Mandatory=$true)]
      [object]$deployOutput
   )
   Write-Host ""
   Write-Host "Deploying firewall rules..."
   $fireWallIps = Get-FirewallIps -deployOutput $deployOutput
   $currentFirewallRules = Get-CurrentFirewallRules -sqlServerId $deployOutput.outputs.sqlServerId.value
   if ($null -ne $currentFirewallRules -and $currentFirewallRules.Count -gt 0) {
      Remove-UnwantedSqlFirewallRules -currentFirewallRules $currentFirewallRules -fireWallIps $fireWallIps
   }
   $missingFirewallIps = $fireWallIps | Where-Object { $currentFirewallRules.startIpAddress -notcontains $_ }
   if ($missingFirewallIps -ne $null -and $missingFirewallIps.Count -gt 0) {
      Add-MissingSqlFirewallRules -missingFirewallIps $missingFirewallIps -deployOutput $deployOutput
   } else {
      Write-Host "No missing firewall IPs to add."
   }
}

function Deploy-DebeziumConnector {
   param (
      [Parameter(Mandatory=$true)]
      [object]$deployOutput,
      [Parameter(Mandatory=$true)]
      [string]$sqlServerPassword,
      [Parameter(Mandatory=$true)]
      [string]$debeziumUser,
      [Parameter(Mandatory=$true)]
      [string]$debeziumPassword
   )
   Write-Host ""
   Write-Host "Deploying Debezium connector..."
   $debeziumEndpoint = $deployOutput.outputs.debeziumEndpoint.value
   $existingConnectors = (Invoke-RestMethod "$debeziumEndpoint/connectors")
   $existingConnectors | ForEach-Object -Begin { $i = 0 } -Process {
      $i++
      Write-Host "Deleting existing connector: $_ ($i of $($existingConnectors.Count))"
      Invoke-RestMethod -Uri "$debeziumEndpoint/connectors/$($_)" -Method DELETE
   }

   $eventhubConnectionString = az eventhubs namespace authorization-rule keys list --resource-group $deployOutput.outputs.resourceGroupName.value --name RootManageSharedAccessKey --namespace-name $deployOutput.outputs.eventhubNamespaceName.value --output tsv --query 'primaryConnectionString'
   $tables = Get-Content '.\sql\setup-cdc\.cdc-tables' | Join-String -Separator ','
   $JSON = (Get-Content '.\debezium\config\sqlserver-connector-config.json' -Raw) `
      -replace '#{EVENTHUBNAMESPACE_HUB_NAME}#', $deployOutput.outputs.eventhubName.value `
      -replace '#{EVENTHUBNAMESPACE_NAME}#', $deployOutput.outputs.eventhubNamespaceName.value `
      -replace '#{AZURE_SQL_SERVER_NAME}#', $deployOutput.outputs.sqlServerName.value `
      -replace '#{AZURE_SQL_DATABASE_USER}#', $debeziumUser `
      -replace '#{AZURE_SQL_DATABASE_PASSWORD}#', $debeziumPassword `
      -replace '#{AZURE_SQL_DATABASE_NAME}#', $deployOutput.outputs.sqlDatabaseName.value `
      -replace '#{EVENTHUBNAMESPACE_CONNECTIONSTRING}#', $eventhubConnectionString `
      -replace '#{CDC_DATABASE_TABLES}#', $tables 

   Write-Host $JSON
   Write-Host "Creating new connector..."
   Invoke-RestMethod "$debeziumEndpoint/connectors/" -Method POST -Body $JSON -ContentType "application/json" -AllowInsecureRedirect
}

function Deploy-Database {
   param (
      [Parameter(Mandatory=$true)]
      [object]$deployOutput,
      [Parameter(Mandatory=$true)]
      [string]$sqlServerPassword
   )
   Write-Host ""
   Write-Host "Deploying Database..."   
   $setupDbScript = Get-Content '.\sql\seed\setup-db.sql' -Raw   
   Invoke-Sqlcmd -ServerInstance "$($deployOutput.outputs.sqlServerName.value).database.windows.net" -Database "$($deployOutput.outputs.sqlDatabaseName.value)" -Username "$($deployOutput.outputs.sqlServerUser.value)" -Password "$sqlServerPassword" -Query $setupDbScript
}

function Deploy-CDC {
   param (
      [Parameter(Mandatory=$true)]
      [object]$deployOutput,
      [Parameter(Mandatory=$true)]
      [string]$sqlServerPassword,
      [Parameter(Mandatory=$true)]
      [string]$debeziumUser,
      [Parameter(Mandatory=$true)]
      [string]$debeziumPassword
   )
   Write-Host ""
   Write-Host "Deploying CDC..."
   
   #prepare cdc user
   $cdcUserScript = (Get-Content '.\sql\setup-cdc\01-setup-cdc-user.sql' -Raw) `
      -replace '#{USER}#', $debeziumUser `
      -replace '#{PASSWORD}#', $debeziumPassword
   
   Invoke-Sqlcmd -ServerInstance "$($deployOutput.outputs.sqlServerName.value).database.windows.net" -Database "$($deployOutput.outputs.sqlDatabaseName.value)" -Username "$($deployOutput.outputs.sqlServerUser.value)" -Password "$sqlServerPassword" -Query $cdcUserScript

   $enableCdcScript = (Get-Content '.\sql\setup-cdc\02-enable-cdc.sql' -Raw)
   Invoke-Sqlcmd -ServerInstance "$($deployOutput.outputs.sqlServerName.value).database.windows.net" -Database "$($deployOutput.outputs.sqlDatabaseName.value)" -Username "$($deployOutput.outputs.sqlServerUser.value)" -Password "$sqlServerPassword" -Query $enableCdcScript

   $tables = Get-Content '.\sql\setup-cdc\.cdc-tables'
   $tables | ForEach-Object {
      $schema = ($_.Split('.'))[0]
      $table = ($_.Split('.'))[1]
      
      Write-Host "Deploying CDC for $schema.$table..."
      $cdcTableScript = (Get-Content '.\sql\setup-cdc\03-enable-cdc-table.sql' -Raw) `
         -replace '#{SCHEMA}#', $schema `
         -replace '#{TABLE}#', $table
      Invoke-Sqlcmd -ServerInstance "$($deployOutput.outputs.sqlServerName.value).database.windows.net" -Database "$($deployOutput.outputs.sqlDatabaseName.value)" -Username "$($deployOutput.outputs.sqlServerUser.value)" -Password "$sqlServerPassword" -Query $cdcTableScript
   }
}

# Main script execution
# Check prerequisites
Ensure-SqlServerModule
# Azure Infra Deploy
$deployOutput = az stack sub create --name ChangeCapture --location swedencentral --template-file ".\iac\main.bicep" --parameters ".\iac\main.bicepparam" sqlServerPassword=$sqlServerDbPassword --dm none --aou detachAll --yes | ConvertFrom-Json
# Post Deployment setup
if($null -ne $deployOutput){
   Deploy-SqlFirewallRules -deployOutput $deployOutput
   Deploy-Database -deployOutput $deployOutput -sqlServerPassword $sqlServerDbPassword
   Deploy-CDC -deployOutput $deployOutput -sqlServerPassword $sqlServerDbPassword -debeziumUser $sqlServerDebeziumUser -debeziumPassword $sqlServerDebeziumPassword
   Deploy-DebeziumConnector -deployOutput $deployOutput -sqlServerPassword $sqlServerDbPassword -debeziumUser $sqlServerDebeziumUser -debeziumPassword $sqlServerDebeziumPassword
   Write-Host "Deployment completed successfully."
}
