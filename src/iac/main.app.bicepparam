using './main.bicep'

param environmentName = 'dev'
param location = 'swedencentral'
param sqlServerUser = 'debezium'
param sqlServerPassword = 'p@ssW0rd'
param changeProcessorImageName = 'acrcorevty2dev.azurecr.io/images/changefeedprocessor'

