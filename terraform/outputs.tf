# Conditional outputs based on what was deployed

# Resource Group outputs
output "resource_group_name" {
  description = "Name of the created resource group"
  value       = local.resolved_resources.resource_group.enabled ? azurerm_resource_group.main[0].name : null
}

output "resource_group_id" {
  description = "ID of the created resource group"
  value       = local.resolved_resources.resource_group.enabled ? azurerm_resource_group.main[0].id : null
}

output "location" {
  description = "Azure region where resources are deployed"
  value       = local.customer_info.location
}

# Storage Account outputs
output "storage_account_name" {
  description = "Name of the created storage account"
  value       = local.resolved_resources.storage_account.enabled ? azurerm_storage_account.main[0].name : null
}

output "storage_account_primary_blob_endpoint" {
  description = "Primary blob endpoint of the storage account"
  value       = local.resolved_resources.storage_account.enabled ? azurerm_storage_account.main[0].primary_blob_endpoint : null
}

output "storage_containers" {
  description = "List of created storage containers"
  value       = local.resolved_resources.storage_account.enabled ? azurerm_storage_container.containers[*].name : []
}

# Key Vault outputs
output "key_vault_name" {
  description = "Name of the created Key Vault"
  value       = local.resolved_resources.key_vault.enabled ? azurerm_key_vault.main[0].name : null
}

output "key_vault_uri" {
  description = "URI of the created Key Vault"
  value       = local.resolved_resources.key_vault.enabled ? azurerm_key_vault.main[0].vault_uri : null
}

output "key_vault_secrets" {
  description = "List of created Key Vault secrets"
  value       = local.resolved_resources.key_vault.enabled ? azurerm_key_vault_secret.secrets[*].name : []
  sensitive   = true
}

# Virtual Network outputs
output "virtual_network_name" {
  description = "Name of the created virtual network"
  value       = local.resolved_resources.virtual_network.enabled ? azurerm_virtual_network.main[0].name : null
}

output "subnet_names" {
  description = "List of created subnet names"
  value       = local.resolved_resources.virtual_network.enabled ? azurerm_subnet.subnets[*].name : []
}

# Summary output
output "deployed_resources" {
  description = "Summary of what resources were deployed"
  value = {
    resource_group    = local.resolved_resources.resource_group.enabled
    storage_account   = local.resolved_resources.storage_account.enabled
    key_vault        = local.resolved_resources.key_vault.enabled
    virtual_network  = local.resolved_resources.virtual_network.enabled
    customer_name    = local.customer_info.name
    environment      = local.customer_info.environment
  }
}