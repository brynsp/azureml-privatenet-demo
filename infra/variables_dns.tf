variable "private_dns_zones" {
  description = "List of Private DNS Zones to create."
  type        = set(string)
  default = [
    "privatelink.api.azureml.ms",
    "privatelink.notebooks.azure.net",
    "privatelink.blob.core.windows.net",
    "privatelink.file.core.windows.net",
    "privatelink.table.core.windows.net",
    "privatelink.queue.core.windows.net",
    "privatelink.vaultcore.azure.net",
    "privatelink.azurecr.io",
    "privatelink.monitor.azure.com",
    "privatelink.ods.opinsights.azure.com",
    "privatelink.oms.opinsights.azure.com"
  ]
}
