param(
   [string]$sqlServerDbPassword = "p@ssW0rd"
)

# Azure Infra Deploy
az stack sub create --name ChangeCapture --location swedencentral --template-file ".\iac\main.bicep" --parameters ".\iac\main.bicepparam" sqlServerPassword=$sqlServerDbPassword --dm none --yes | ConvertFrom-Json
