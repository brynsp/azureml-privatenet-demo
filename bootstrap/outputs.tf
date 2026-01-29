output "state_resource_group_name" {
  value       = azurerm_resource_group.state.name
  description = "Resource group name for the state storage account."
}

output "state_storage_account_name" {
  value       = azurerm_storage_account.state.name
  description = "Storage account name for Terraform state."
}

output "state_container_name" {
  value       = azurerm_storage_container.state.name
  description = "Blob container name for Terraform state."
}

output "backend_key" {
  value       = "infra.tfstate"
  description = "Default backend key to use in infra backend configuration."
}
