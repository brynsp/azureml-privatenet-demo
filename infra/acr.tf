module "acr" {
  source  = "Azure/avm-res-containerregistry-registry/azurerm"
  version = "0.5.0"

  name                = "acrazml${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = var.tags

  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = false
  zone_redundancy_enabled       = false

  private_endpoints = {
    registry = {
      name                          = "pe-acr"
      subnet_resource_id            = module.vnet.subnets["subnet-private-endpoints"].resource_id
      private_dns_zone_resource_ids = [module.private_dns_zones["privatelink.azurecr.io"].resource_id]
      subresource_name              = "registry"
    }
  }
}
