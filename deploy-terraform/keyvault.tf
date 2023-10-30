resource "azurerm_key_vault" "kv" {
  name                       = "kv-${local.name}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

}

resource "azurerm_key_vault_access_policy" "sp" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Create",
    "Get",
    "Purge",
    "Recover",
    "Delete"
  ]

  secret_permissions = [
    "Set",
    "Purge",
    "Get",
    "List",
    "Delete"
  ]

  certificate_permissions = [
    "Purge"
  ]

  storage_permissions = [
    "Purge"
  ]

}

resource "azurerm_key_vault_access_policy" "apim" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_api_management.apim.identity[0].principal_id

  key_permissions = [
  ]

  secret_permissions = [
    "Get",
    "List",
  ]

  certificate_permissions = [
  ]

  storage_permissions = [
  ]

}

resource "azurerm_key_vault_secret" "openaikey" {
  depends_on = [ azurerm_key_vault_access_policy.sp, azurerm_key_vault_access_policy.apim ]
  name         = "openaikey"
  value        = azurerm_cognitive_account.this.primary_access_key
  key_vault_id = azurerm_key_vault.kv.id
}