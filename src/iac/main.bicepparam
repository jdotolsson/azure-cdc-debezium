using './main.bicep'

param environmentName = 'dev'
param location = 'swedencentral'
param sqlServerUser = 'debezium'
param sqlServerPassword = 'p@ssW0rd'
param changeProcessorImageName = 'mcr.microsoft.com/azure-functions/dotnet8-quickstart-demo:1.0'

