module "bpcalc-fe" {
  source = "./container-service"

  app_name                     = "bpcalc-fe"
  resource_group_name          = azurerm_resource_group.bpcalc.name
  container_app_environment_id = azurerm_container_app_environment.bpcalc.id

  image_registry = azurerm_container_registry.bpcalc.login_server
  image_name     = "bpapp-fe"
  image_tag      = "sha-e1f97cd"

  max_replicas = 3
  cpu          = 0.25
  memory       = "0.5Gi"
  port         = 22137

  green = 100
  blue  = 0

  external_ingress = true

  liveness_probe = {
    initial_delay           = 15
    interval_seconds        = 10
    failure_count_threshold = 5
    path                    = "/"
    port                    = 22137
    transport               = "HTTP"
  }

  env_vars = {
    APP_NAME            = "BP Category Calculator"
    DATABASE_URI        = "${azurerm_cosmosdb_account.db.connection_strings[0]}"
    DATABASE_NAME       = local.cosmosdb_db_name
    DATABASE_COLLECTION = local.cosmosdb_col_name
    WEBSERVICE_URI      = "https://${data.azurerm_container_app.be.ingress[0].fqdn}/"
    PORT                = "22137"
  }
}