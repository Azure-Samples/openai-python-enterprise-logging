resource "azurerm_cognitive_account" "this" {
  name                  = local.name
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  kind                  = "OpenAI"
  sku_name              = "S0"
  custom_subdomain_name = local.name
  tags                  = local.tags
}

resource "azurerm_cognitive_deployment" "this" {
  name                 = "model-${local.name}"
  cognitive_account_id = azurerm_cognitive_account.this.id
  model {
    format  = "OpenAI"
    name    = var.model
    version = var.model_version
  }
  scale {
    type = "Standard"
  }
}