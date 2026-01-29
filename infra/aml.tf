module "aml_workspace" {
  source  = "Azure/avm-res-machinelearningservices-workspace/azurerm"
  version = "0.9.0"

  name                = "mlw-azml-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = var.tags

  public_network_access_enabled = false

  workspace_managed_network = var.aml_workspace_enable_managed_network ? {
    isolation_mode = var.aml_workspace_managed_network_isolation_mode
    spark_ready    = true
    outbound_rules = {}
    firewall_sku   = "Standard"
  } : {
    isolation_mode = "Disabled"
    spark_ready    = false
    outbound_rules = {}
    firewall_sku   = "Standard"
  }

  provision_network_now_enabled = var.aml_workspace_enable_managed_network ? var.aml_workspace_provision_network_now_enabled : false

  managed_identities = {
    system_assigned = true
  }

  storage_account = {
    resource_id = module.storage_account.resource_id
  }

  key_vault = {
    resource_id = module.key_vault.resource_id
  }

  container_registry = {
    resource_id = module.acr.resource_id
  }

  application_insights = {
    resource_id = module.application_insights.resource_id
  }

  depends_on = [azurerm_resource_group.this]
}

resource "azurerm_private_endpoint" "aml_workspace" {
  name                = "pe-aml-workspace"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = module.vnet.subnets["subnet-private-endpoints"].resource_id
  tags                = var.tags

  private_service_connection {
    name                           = "pse-aml-workspace"
    private_connection_resource_id = module.aml_workspace.resource_id
    is_manual_connection           = false
    subresource_names              = ["amlworkspace"]
  }

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      module.private_dns_zones["privatelink.api.azureml.ms"].resource_id,
      module.private_dns_zones["privatelink.notebooks.azure.net"].resource_id
    ]
  }
}
