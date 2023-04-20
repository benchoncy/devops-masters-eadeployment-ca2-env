resource "azurerm_management_lock" "drift_lock" {
  depends_on = [
    azurerm_cosmosdb_mongo_collection.db,
    module.bpcalc-be,
    module.bpcalc-fe
  ]
  name       = "terraform-drift-lock"
  scope      = azurerm_resource_group.bpcalc.id
  lock_level = "ReadOnly"
  notes      = "Changes to this resource group should be done via terraform"
}