resource "azurerm_monitor_private_link_scope" "ampls" {
  name                = "ampls-azml-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

resource "azurerm_private_endpoint" "ampls" {
  name                = "pe-ampls"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = module.vnet.subnets["subnet-private-endpoints"].resource_id

  private_service_connection {
    name                           = "psc-ampls"
    private_connection_resource_id = azurerm_monitor_private_link_scope.ampls.id
    is_manual_connection           = false
    subresource_names              = ["azuremonitor"]
  }

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      module.private_dns_zones["privatelink.monitor.azure.com"].resource_id,
      module.private_dns_zones["privatelink.ods.opinsights.azure.com"].resource_id,
      module.private_dns_zones["privatelink.oms.opinsights.azure.com"].resource_id,
      module.private_dns_zones["privatelink.blob.core.windows.net"].resource_id
    ]
  }
}

module "log_analytics" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "0.4.2"

  name                = "law-azml-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = var.tags

  log_analytics_workspace_sku                        = "PerGB2018"
  log_analytics_workspace_retention_in_days          = 30
  log_analytics_workspace_internet_ingestion_enabled = false
  log_analytics_workspace_internet_query_enabled     = false
}

resource "azurerm_monitor_private_link_scoped_service" "law" {
  name                = "ampls-law-link"
  resource_group_name = azurerm_resource_group.this.name
  scope_name          = azurerm_monitor_private_link_scope.ampls.name
  linked_resource_id  = module.log_analytics.resource.id
}

module "application_insights" {
  source  = "Azure/avm-res-insights-component/azurerm"
  version = "0.2.0"

  name                = "appi-azml-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = var.tags

  workspace_id     = module.log_analytics.resource.id
  application_type = "web"

  internet_ingestion_enabled = false
  internet_query_enabled     = false
}

resource "azurerm_monitor_private_link_scoped_service" "appi" {
  name                = "ampls-appi-link"
  resource_group_name = azurerm_resource_group.this.name
  scope_name          = azurerm_monitor_private_link_scope.ampls.name
  linked_resource_id  = module.application_insights.resource_id
}
