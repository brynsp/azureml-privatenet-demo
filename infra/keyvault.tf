data "azurerm_client_config" "current" {}

data "http" "public_ip" {
  count = var.resource_group_security_control_ignore ? 1 : 0
  url   = "https://api.ipify.org"
}

locals {
  terraform_public_ip_cidr = var.resource_group_security_control_ignore ? "${chomp(data.http.public_ip[0].response_body)}/32" : null
  key_vault_ip_rules       = local.terraform_public_ip_cidr != null ? [local.terraform_public_ip_cidr] : []
}

module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.2"

  name                = "kv-azml-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = var.tags
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name = "standard"

  public_network_access_enabled = var.resource_group_security_control_ignore

  network_acls = {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = local.key_vault_ip_rules
  }

  private_endpoints = {
    vault = {
      name                          = "pe-kv"
      subnet_resource_id            = module.vnet.subnets["subnet-private-endpoints"].resource_id
      private_dns_zone_resource_ids = [module.private_dns_zones["privatelink.vaultcore.azure.net"].resource_id]
      subresource_name              = "vault"
    }
  }
}
