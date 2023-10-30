resource "azurerm_eventhub_namespace" "this" {
  name                = "ehn${local.name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Basic"
  capacity            = 1

  tags = local.tags
}

resource "azurerm_eventhub" "this" {
  name                = "apimlogger"
  namespace_name      = azurerm_eventhub_namespace.this.name
  resource_group_name = azurerm_resource_group.rg.name
  partition_count     = 2
  message_retention   = 1
}