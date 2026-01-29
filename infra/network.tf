module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.16.0"

  name          = "vnet-azml-${var.location}"
  parent_id     = azurerm_resource_group.this.id
  location      = azurerm_resource_group.this.location
  address_space = var.vnet_address_space
  tags          = var.tags

  subnets = {
    "subnet-private-endpoints" = {
      name             = "snet-pe"
      address_prefixes = [var.subnet_prefixes["subnet-private-endpoints"]]
      network_security_group = {
        id = module.nsg_pe.resource_id
      }
    }
    "subnet-training" = {
      name             = "snet-training"
      address_prefixes = [var.subnet_prefixes["subnet-training"]]
      network_security_group = {
        id = module.nsg_training.resource_id
      }
    }
    "subnet-inference" = {
      name             = "snet-inference"
      address_prefixes = [var.subnet_prefixes["subnet-inference"]]
      network_security_group = {
        id = module.nsg_inference.resource_id
      }
    }
    "AzureBastionSubnet" = {
      name             = "AzureBastionSubnet"
      address_prefixes = [var.subnet_prefixes["AzureBastionSubnet"]]
      network_security_group = {
        id = module.nsg_bastion.resource_id
      }
    }
    "subnet-jumpbox" = {
      name             = "snet-jumpbox"
      address_prefixes = [var.subnet_prefixes["subnet-jumpbox"]]
      network_security_group = {
        id = module.nsg_jumpbox.resource_id
      }
      nat_gateway = {
        id = azurerm_nat_gateway.this.id
      }
    }
  }
}


# NAT Gateway for Jumpbox Internet Access
resource "azurerm_public_ip" "nat_gateway" {
  name                = "pip-nat-${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_nat_gateway" "this" {
  name                = "nat-gateway-${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "Standard"
  tags                = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  nat_gateway_id       = azurerm_nat_gateway.this.id
  public_ip_address_id = azurerm_public_ip.nat_gateway.id
}



