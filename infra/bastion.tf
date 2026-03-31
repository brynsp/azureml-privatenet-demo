# Public IP for Bastion
resource "azurerm_public_ip" "bastion" {
  name                = "pip-bastion-${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Azure Bastion Host
resource "azurerm_bastion_host" "main" {
  name                = "bastion-${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
  sku                 = "Standard"
  tunneling_enabled   = true
  kerberos_enabled    = true

  ip_configuration {
    name                 = "configuration"
    subnet_id            = module.vnet.subnets["AzureBastionSubnet"].resource_id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}

# Jumpbox Network Interface
resource "azurerm_network_interface" "jumpbox" {
  name                = "nic-jumpbox-${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = module.vnet.subnets["subnet-jumpbox"].resource_id
    private_ip_address_allocation = "Dynamic"
  }
}

# Random Password for Windows Jumpbox
resource "random_password" "jumpbox_password" {
  length           = 16
  special          = true
  override_special = "!@#$%"
}

# Key Vault Secret for Jumpbox Password
resource "azurerm_key_vault_secret" "jumpbox_password" {
  name         = "jumpbox-password"
  value        = random_password.jumpbox_password.result
  key_vault_id = module.key_vault.resource_id

  depends_on = [
    azurerm_role_assignment.current_user_kv_officer
  ]
}

# Key Vault Secret for Jumpbox Admin Username
resource "azurerm_key_vault_secret" "jumpbox_username" {
  name         = "jumpbox-username"
  value        = var.jumpbox_admin_username
  key_vault_id = module.key_vault.resource_id

  depends_on = [
    azurerm_role_assignment.current_user_kv_officer
  ]
}

# Role Assignment for User to access Key Vault Secrets (needed for Bastion password retrieval)
resource "azurerm_role_assignment" "current_user_kv_officer" {
  scope                = module.key_vault.resource_id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Windows Jumpbox VM
resource "azurerm_windows_virtual_machine" "jumpbox" {
  name                = "vm-jumpbox-${random_string.suffix.result}"
  computer_name       = "win-jumpbox"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  size                = "Standard_D4s_v3"
  license_type        = var.jumpbox_enable_hybrid_benefit ? "Windows_Server" : null
  admin_username      = var.jumpbox_admin_username
  admin_password      = random_password.jumpbox_password.result
  network_interface_ids = [
    azurerm_network_interface.jumpbox.id,
  ]
  tags = var.tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.jumpbox_image_publisher
    offer     = var.jumpbox_image_offer
    sku       = var.jumpbox_image_sku
    version   = var.jumpbox_image_version
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_virtual_machine_extension" "aad_login" {
  name                       = "AADLoginForWindows"
  virtual_machine_id         = azurerm_windows_virtual_machine.jumpbox.id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
}

resource "azurerm_role_assignment" "vm_admin_login" {
  scope                = azurerm_windows_virtual_machine.jumpbox.id
  role_definition_name = "Virtual Machine Administrator Login"
  principal_id         = data.azurerm_client_config.current.object_id
}
