module "storage_account" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.6.7"

  name                = "stazml${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = var.tags

  account_tier             = "Standard"
  account_replication_type = "LRS"

  public_network_access_enabled = false
  shared_access_key_enabled     = false

  network_rules = {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  private_endpoints = {
    blob = {
      name                          = "pe-st-blob"
      subnet_resource_id            = module.vnet.subnets["subnet-private-endpoints"].resource_id
      private_dns_zone_resource_ids = [module.private_dns_zones["privatelink.blob.core.windows.net"].resource_id]
      subresource_name              = "blob"
    }
    file = {
      name                          = "pe-st-file"
      subnet_resource_id            = module.vnet.subnets["subnet-private-endpoints"].resource_id
      private_dns_zone_resource_ids = [module.private_dns_zones["privatelink.file.core.windows.net"].resource_id]
      subresource_name              = "file"
    }
    table = {
      name                          = "pe-st-table"
      subnet_resource_id            = module.vnet.subnets["subnet-private-endpoints"].resource_id
      private_dns_zone_resource_ids = [module.private_dns_zones["privatelink.table.core.windows.net"].resource_id]
      subresource_name              = "table"
    }
    queue = {
      name                          = "pe-st-queue"
      subnet_resource_id            = module.vnet.subnets["subnet-private-endpoints"].resource_id
      private_dns_zone_resource_ids = [module.private_dns_zones["privatelink.queue.core.windows.net"].resource_id]
      subresource_name              = "queue"
    }
  }
}
