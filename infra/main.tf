resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags = var.tags
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}
