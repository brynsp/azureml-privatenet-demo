module "nsg_pe" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.0"

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  name                = "nsg-pe"
  tags                = var.tags

  security_rules = {
    "AllowVnetInBound" = {
      name                       = "AllowVnetInBound"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    }
  }
}

module "nsg_training" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.0"

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  name                = "nsg-training"
  tags                = var.tags

  security_rules = {
    "BatchNodeManagement" = {
      name                       = "BatchNodeManagement"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_ranges    = ["29876", "29877"]
      source_address_prefix      = "BatchNodeManagement"
      destination_address_prefix = "*"
    }
    "AzureMachineLearning" = {
      name                       = "AzureMachineLearning"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "44224"
      source_address_prefix      = "AzureMachineLearning"
      destination_address_prefix = "*"
    }
  }
}

module "nsg_inference" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.0"

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  name                = "nsg-inference"
  tags                = var.tags

  security_rules = {
    "AzureMachineLearning" = {
      name                       = "AzureMachineLearning"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "44224"
      source_address_prefix      = "AzureMachineLearning"
      destination_address_prefix = "*"
    }
  }
}

module "nsg_jumpbox" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.0"

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  name                = "nsg-jumpbox"
  tags                = var.tags

  security_rules = {
    "AllowBastionInBound" = {
      name                       = "AllowBastionInBound"
      priority                   = 1010
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_ranges    = ["22", "3389"]
      source_address_prefix      = var.subnet_prefixes["AzureBastionSubnet"]
      destination_address_prefix = "*"
    }
  }
}

module "nsg_bastion" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.0"

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  name                = "nsg-bastion"
  tags                = var.tags

  security_rules = {
    "AllowHttpsInBound" = {
      name                       = "AllowHttpsInBound"
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    }
    "AllowGatewayManagerInBound" = {
      name                       = "AllowGatewayManagerInBound"
      priority                   = 130
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "GatewayManager"
      destination_address_prefix = "*"
    }
    "AllowAzureLoadBalancerInBound" = {
      name                       = "AllowAzureLoadBalancerInBound"
      priority                   = 140
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "*"
    }
    "AllowBastionHostCommunication" = {
      name                       = "AllowBastionHostCommunication"
      priority                   = 150
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_ranges    = ["8080", "5701"]
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    }
    "AllowSshRdpOutBound" = {
      name                       = "AllowSshRdpOutBound"
      priority                   = 100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_ranges    = ["22", "3389"]
      source_address_prefix      = "*"
      destination_address_prefix = "VirtualNetwork"
    }
    "AllowAzureCloudOutBound" = {
      name                       = "AllowAzureCloudOutBound"
      priority                   = 110
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "AzureCloud"
    }
    "AllowBastionCommunication" = {
      name                       = "AllowBastionCommunication"
      priority                   = 120
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_ranges    = ["8080", "5701"]
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    }
    "AllowGetSessionInformation" = {
      name                       = "AllowGetSessionInformation"
      priority                   = 130
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "Internet"
    }
  }
}

