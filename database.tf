locals {
  cosmosdb_account_name = "cosmos-db-bpcalc"
  cosmosdb_db_name      = "bpcalc-mongo-db"
  cosmosdb_col_name     = "bpcalc-mongo-db"
}

resource "azurerm_cosmosdb_account" "db" {
  name                = local.cosmosdb_account_name
  location            = azurerm_resource_group.bpcalc.location
  resource_group_name = azurerm_resource_group.bpcalc.name
  offer_type          = "Standard"
  kind                = "MongoDB"

  enable_automatic_failover = true

  backup {
    type                = "Periodic"
    interval_in_minutes = 1440 # 24 hours
    retention_in_hours  = 720  # 30 days
  }

  capabilities {
    name = "EnableAggregationPipeline"
  }

  capabilities {
    name = "mongoEnableDocLevelTTL"
  }

  capabilities {
    name = "MongoDBv3.4"
  }

  capabilities {
    name = "EnableMongo"
  }

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }

  geo_location {
    location          = "uksouth"
    failover_priority = 1
  }

  geo_location {
    location          = "westeurope"
    failover_priority = 0
  }
}

resource "azurerm_cosmosdb_mongo_database" "db" {
  depends_on = [
    azurerm_cosmosdb_account.db
  ]
  name                = local.cosmosdb_db_name
  resource_group_name = azurerm_resource_group.bpcalc.name
  account_name        = local.cosmosdb_account_name
  throughput          = 400
}

resource "azurerm_cosmosdb_mongo_collection" "db" {
  depends_on = [
    azurerm_cosmosdb_mongo_database.db
  ]
  name                = local.cosmosdb_col_name
  resource_group_name = azurerm_resource_group.bpcalc.name
  account_name        = local.cosmosdb_account_name
  database_name       = local.cosmosdb_db_name
  throughput          = 400

  index {
    keys   = ["_id"]
    unique = true
  }
}