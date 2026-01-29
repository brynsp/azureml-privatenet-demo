variable "subscription_id" {
  description = "The Subscription ID where the state resources will be created."
  type        = string
}

variable "location" {
  description = "The Azure region where the state resources will be created."
  type        = string
  default     = "centralus"
}

variable "tags" {
  description = "A mapping of tags to assign to the state resources."
  type        = map(string)
  default     = {}
}

variable "state_resource_group_name" {
  description = "Resource group name for Terraform state storage."
  type        = string
}

variable "state_storage_account_name" {
  description = "Optional storage account name for Terraform state (3-24 lowercase letters/numbers). If null, a name is generated as sttfstateXXXXX."
  type        = string
  default     = null
}

variable "state_container_name" {
  description = "Blob container name for Terraform state."
  type        = string
  default     = "tfstate"
}

variable "state_access_principal_id" {
  description = "Optional principal object ID to grant Storage Blob Data Owner for state access. Defaults to the current identity."
  type        = string
  default     = null
}

variable "enable_state_role_assignment" {
  description = "Whether to create Storage Blob Data Owner role assignment for the state storage account."
  type        = bool
  default     = true
}

variable "resource_group_security_control_ignore" {
  description = "Whether to add SecurityControl=Ignore tag on the state resource group for policy exemptions."
  type        = bool
  default     = false
}
