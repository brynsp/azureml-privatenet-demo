module "private_dns_zones" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "0.4.4"

  for_each = var.private_dns_zones

  parent_id   = azurerm_resource_group.this.id
  domain_name = each.value
  tags        = var.tags

  virtual_network_links = {
    vnet_link = {
      name               = "vnet-link"
      virtual_network_id = module.vnet.resource_id
    }
  }
}
