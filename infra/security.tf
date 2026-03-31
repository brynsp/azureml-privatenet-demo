locals {
  defender_container_plans = var.enable_defender_for_containers ? [
    "Containers",
    "ContainerRegistry",
  ] : []

  defender_optional_plans = var.manage_defender_plans ? [
    "AppServices",
    "KeyVaults",
    "Arm",
    "StorageAccounts",
    "VirtualMachines",
  ] : []

  defender_plans = toset(concat(local.defender_container_plans, local.defender_optional_plans))
}

resource "azurerm_security_center_subscription_pricing" "defender_plans" {
  for_each = local.defender_plans

  tier          = "Standard"
  resource_type = each.value
}

resource "azurerm_security_center_contact" "main" {
  count = var.manage_defender_contact ? 1 : 0

  name  = "default"
  email = var.security_contact_email
  # NOTE: This is a placeholder phone number. Update this value to a valid contact number
  # before enabling `manage_defender_contact` in production.
  phone = "555-555-5555"

  alert_notifications = true
  alerts_to_admins    = true
}
