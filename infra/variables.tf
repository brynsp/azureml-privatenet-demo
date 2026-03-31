locals {
  allowed_jumpbox_auth_modes = ["entra", "password"]
  allowed_aml_isolation_modes = [
    "Disabled",
    "AllowInternetOutbound",
    "AllowOnlyApprovedOutbound"
  ]
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the resources."
  type        = string
}

variable "location" {
  description = "The Azure region where the resources will be created."
  type        = string
  default     = "centralus"
}

variable "subscription_id" {
  description = "The Subscription ID where the resources will be created."
  type        = string
}

variable "vnet_address_space" {
  description = "The address space for the Virtual Network."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_prefixes" {
  description = "A map of subnet names to their address prefixes."
  type        = map(string)
  default = {
    "subnet-private-endpoints" = "10.0.0.0/24"
    "subnet-training"          = "10.0.1.0/24"
    "subnet-inference"         = "10.0.2.0/24"
    "AzureBastionSubnet"       = "10.0.3.0/26"
    "subnet-jumpbox"           = "10.0.4.0/24"
  }
}

variable "tags" {
  description = "A mapping of tags to assign to the resources."
  type        = map(string)
  default = {
    Environment = "Development"
    Project     = "AzureML-Private"
  }
}

variable "ds_vm_size" {
  description = "The VM size for the Data Science Compute Instance."
  type        = string
  default     = "Standard_DS3_v2"
}

variable "training_cluster_vm_size" {
  description = "The VM size for the Training Compute Cluster."
  type        = string
  default     = "Standard_D2_v2"
}

variable "security_contact_email" {
  description = "The email address for security alerts."
  type        = string
  default     = "admin@example.com"
}

variable "enable_defender_for_containers" {
  description = "Whether to enable Defender for Containers (includes ACR image scanning) via subscription pricing."
  type        = bool
  default     = true
}

variable "manage_defender_plans" {
  description = "Whether to manage Defender for Cloud subscription pricing for non-container resource types with Terraform."
  type        = bool
  default     = false
}

variable "jumpbox_auth_mode" {
  description = "Authentication mode for the jumpbox. Use 'entra' (default) or 'password'."
  type        = string
  default     = "entra"

  validation {
    condition     = contains(local.allowed_jumpbox_auth_modes, var.jumpbox_auth_mode)
    error_message = "jumpbox_auth_mode must be either 'entra' or 'password'."
  }
}

variable "jumpbox_admin_username" {
  description = "Local admin username for the jumpbox VM (stored in Key Vault)."
  type        = string
  default     = "azureadmin"
}

variable "jumpbox_enable_hybrid_benefit" {
  description = "Whether to enable Azure Hybrid Benefit for the Windows jumpbox."
  type        = bool
  default     = true
}

variable "jumpbox_image_publisher" {
  description = "Jumpbox image publisher."
  type        = string
  default     = "MicrosoftWindowsServer"
}

variable "jumpbox_image_offer" {
  description = "Jumpbox image offer."
  type        = string
  default     = "WindowsServer"
}

variable "jumpbox_image_sku" {
  description = "Jumpbox image SKU. Use a non-Core Windows Server 2025 Datacenter SKU available in your region."
  type        = string
  default     = "2025-datacenter"

  validation {
    condition     = !can(regex("(?i)core", var.jumpbox_image_sku))
    error_message = "jumpbox_image_sku must be a Desktop Experience SKU (not Core)."
  }
}

variable "jumpbox_image_version" {
  description = "Jumpbox image version."
  type        = string
  default     = "latest"
}

variable "aml_workspace_enable_managed_network" {
  description = "Whether to enable managed VNet for the AML workspace."
  type        = bool
  default     = true
}

variable "manage_defender_contact" {
  description = "Whether to manage the Defender for Cloud security contact with Terraform."
  type        = bool
  default     = false
}

variable "enable_compute_instance" {
  description = "Whether to create the AML compute instance."
  type        = bool
  default     = true
}

variable "enable_compute_cluster" {
  description = "Whether to create the AML compute cluster."
  type        = bool
  default     = true
}

variable "aml_workspace_managed_network_isolation_mode" {
  description = "Managed network isolation mode for the AML workspace."
  type        = string
  default     = "AllowInternetOutbound"

  validation {
    condition     = contains(local.allowed_aml_isolation_modes, var.aml_workspace_managed_network_isolation_mode)
    error_message = "aml_workspace_managed_network_isolation_mode must be one of: Disabled, AllowInternetOutbound, AllowOnlyApprovedOutbound."
  }
}

variable "aml_workspace_provision_network_now_enabled" {
  description = "Whether to provision the AML managed network immediately."
  type        = bool
  default     = true
}
