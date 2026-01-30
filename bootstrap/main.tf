data "azurerm_client_config" "current" {}

locals {
  state_access_principal_id  = coalesce(var.state_access_principal_id, data.azurerm_client_config.current.object_id)
  state_storage_account_name = coalesce(var.state_storage_account_name, "sttfstate${random_string.state_sa_suffix.result}")
}

resource "random_string" "state_sa_suffix" {
  length  = 5
  upper   = false
  special = false
}

resource "azurerm_resource_group" "state" {
  name     = var.state_resource_group_name
  location = var.location
  tags = var.tags
}

resource "azurerm_storage_account" "state" {
  name                     = local.state_storage_account_name
  resource_group_name      = azurerm_resource_group.state.name
  location                 = azurerm_resource_group.state.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  shared_access_key_enabled = false

  # NOTE: Public network access is intentionally enabled for the bootstrap
  # state storage account so that Terraform can establish remote state during
  # initial setup before any private endpoints or network restrictions exist.
  # After bootstrap, consumers should consider disabling public network access
  # and/or applying stricter network rules in accordance with their security
  # requirements.
  public_network_access_enabled = true

  min_tls_version = "TLS1_2"

  tags = var.tags
}

resource "azurerm_storage_container" "state" {
  name                  = var.state_container_name
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}

resource "azurerm_role_assignment" "state_blob_owner" {
  count                = var.enable_state_role_assignment ? 1 : 0
  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = local.state_access_principal_id
}
