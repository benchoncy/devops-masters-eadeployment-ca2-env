module "bpcalc-be" {
  source = "./container-service"

  app_name                     = "bpcalc-be"
  resource_group_name          = azurerm_resource_group.bpcalc.name
  container_app_environment_id = azurerm_container_app_environment.bpcalc.id

  image_registry = azurerm_container_registry.bpcalc.login_server
  image_name     = "bpapp-be"
  image_tag      = "sha-ea39216"

  max_replicas = 3
  cpu          = 0.25
  memory       = "0.5Gi"
  port         = 8080

  green = 100
  blue  = 0

  liveness_probe = {
    initial_delay           = 15
    interval_seconds        = 10
    failure_count_threshold = 5
    path                    = "/"
    port                    = 8080
    transport               = "HTTP"
  }

  env_vars = {
    FLASK_SECRET_KEY    = "${random_string.secret_key.result}"
    DATABASE_URI        = "${azurerm_cosmosdb_account.db.connection_strings[0]}"
    DATABASE_NAME       = local.cosmosdb_db_name
    DATABASE_COLLECTION = local.cosmosdb_col_name
  }
}

resource "random_string" "secret_key" {
  length  = 16
  special = false
}

data "azurerm_container_app" "be" {
  name                = module.bpcalc-be.app_name
  resource_group_name = azurerm_resource_group.bpcalc.name
}