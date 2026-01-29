locals {
  diagnostic_targets = {
    aml_workspace = module.aml_workspace.resource_id
    acr           = module.acr.resource_id
    key_vault     = module.key_vault.resource_id
    storage       = module.storage_account.resource_id
    vnet          = module.vnet.resource_id
    nsg_pe        = module.nsg_pe.resource_id
    nsg_training  = module.nsg_training.resource_id
    nsg_inference = module.nsg_inference.resource_id
    nsg_jumpbox   = module.nsg_jumpbox.resource_id
    nsg_bastion   = module.nsg_bastion.resource_id
    bastion       = azurerm_bastion_host.main.id
  }

  diagnostic_category_groups = {
    for key, value in data.azurerm_monitor_diagnostic_categories.targets :
    key => toset(value.log_category_groups)
  }

  diagnostic_categories = {
    for key, value in data.azurerm_monitor_diagnostic_categories.targets :
    key => toset(value.log_category_types)
  }

  diagnostic_metrics = {
    for key, value in data.azurerm_monitor_diagnostic_categories.targets :
    key => toset(value.metrics)
  }
}

data "azurerm_monitor_diagnostic_categories" "targets" {
  for_each    = local.diagnostic_targets
  resource_id = each.value
}

resource "azurerm_monitor_diagnostic_setting" "targets" {
  for_each                   = local.diagnostic_targets
  name                       = "diag-${each.key}"
  target_resource_id         = each.value
  log_analytics_workspace_id = module.log_analytics.resource.id

  dynamic "enabled_log" {
    for_each = length(local.diagnostic_category_groups[each.key]) > 0 ? local.diagnostic_category_groups[each.key] : []
    content {
      category_group = enabled_log.value
    }
  }

  dynamic "enabled_log" {
    for_each = length(local.diagnostic_category_groups[each.key]) == 0 ? local.diagnostic_categories[each.key] : []
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = local.diagnostic_metrics[each.key]
    content {
      category = metric.value
      enabled  = true
    }
  }
}
