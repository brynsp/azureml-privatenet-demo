resource "azurerm_security_center_subscription_pricing" "defender_plans" {
  for_each = var.manage_defender_plans ? toset([
    "AppServices",
    "ContainerRegistry",
    "KeyVaults",
    "Arm",
    "StorageAccounts",
    "VirtualMachines",
    "Containers"
  ]) : toset([])

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
