resource "azurerm_user_assigned_identity" "compute" {
  count               = var.enable_compute_instance ? 1 : 0
  name                = "uai-compute-${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

resource "azurerm_role_assignment" "compute_storage_blob" {
  count                = var.enable_compute_instance ? 1 : 0
  scope                = module.storage_account.resource_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.compute[0].principal_id
}

resource "azurerm_role_assignment" "compute_storage_file" {
  count                = var.enable_compute_instance ? 1 : 0
  scope                = module.storage_account.resource_id
  role_definition_name = "Storage File Data Privileged Contributor"
  principal_id         = azurerm_user_assigned_identity.compute[0].principal_id
}

resource "azurerm_role_assignment" "compute_keyvault" {
  count                = var.enable_compute_instance ? 1 : 0
  scope                = module.key_vault.resource_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.compute[0].principal_id
}

resource "azurerm_role_assignment" "compute_acr" {
  count                = var.enable_compute_instance ? 1 : 0
  scope                = module.acr.resource_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.compute[0].principal_id
}

resource "azurerm_machine_learning_compute_instance" "main" {
  count                         = var.enable_compute_instance ? 1 : 0
  name                          = "ci-dev-${random_string.suffix.result}"
  machine_learning_workspace_id = module.aml_workspace.resource_id
  virtual_machine_size          = var.ds_vm_size
  subnet_resource_id            = var.aml_workspace_enable_managed_network ? null : module.vnet.subnets["subnet-training"].resource_id
  tags                          = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.compute[0].id]
  }

  depends_on = [
    azurerm_role_assignment.compute_storage_blob,
    azurerm_role_assignment.compute_storage_file,
    azurerm_role_assignment.compute_keyvault,
    azurerm_role_assignment.compute_acr
  ]
}

resource "azurerm_machine_learning_compute_cluster" "main" {
  count                         = var.enable_compute_cluster ? 1 : 0
  name                          = "cc-training-${random_string.suffix.result}"
  location                      = azurerm_resource_group.this.location
  machine_learning_workspace_id = module.aml_workspace.resource_id
  vm_priority                   = "Dedicated"
  vm_size                       = var.training_cluster_vm_size
  subnet_resource_id            = var.aml_workspace_enable_managed_network ? null : module.vnet.subnets["subnet-training"].resource_id
  tags                          = var.tags

  identity {
    type = "SystemAssigned"
  }

  scale_settings {
    min_node_count                       = 0
    max_node_count                       = 2
    scale_down_nodes_after_idle_duration = "PT120S" # 2 minutes
  }
}
