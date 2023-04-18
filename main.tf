resource "azurerm_resource_group" "bpcalc" {
  name     = "eadeployment-ca2"
  location = "West Europe"
}

resource "azurerm_container_registry" "bpcalc" {
  name                = "bpcalc"
  resource_group_name = azurerm_resource_group.bpcalc.name
  location            = azurerm_resource_group.bpcalc.location
  sku                 = "Basic"
  admin_enabled       = false
}

resource "azurerm_log_analytics_workspace" "target" {
  name                = "bpcalc-${terraform.workspace}"
  location            = azurerm_resource_group.bpcalc.location
  resource_group_name = azurerm_resource_group.bpcalc.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "bpcalc" {
  name                       = "bpcalc-env-${terraform.workspace}"
  location                   = azurerm_resource_group.bpcalc.location
  resource_group_name        = azurerm_resource_group.bpcalc.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.target.id
}