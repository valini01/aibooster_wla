terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Load customer configuration from root directory
locals {
  config = yamldecode(file("${path.root}/customer-config.yml"))
  
  # Extract configuration sections
  customer_info = local.config.customer_info
  resources = local.config.resources
  advanced_settings = local.config.advanced_settings
  
  # Dependency management - automatically enable dependencies
  resolved_resources = {
    # Resource Group - Required if any other resource is enabled
    resource_group = {
      enabled = (local.resources.resource_group.enabled || 
                local.resources.storage_account.enabled || 
                local.resources.key_vault.enabled ||
                (local.resources.virtual_network != null ? local.resources.virtual_network.enabled : false))
      config = local.resources.resource_group
    }
    
    # Storage Account
    storage_account = {
      enabled = local.resources.storage_account.enabled
      config = local.resources.storage_account
    }
    
    # Key Vault  
    key_vault = {
      enabled = local.resources.key_vault.enabled
      config = local.resources.key_vault
    }
    
    # Virtual Network - Required if private endpoints are enabled
    virtual_network = {
      enabled = ((local.resources.virtual_network != null ? local.resources.virtual_network.enabled : false) || 
                (local.advanced_settings.storage_private_endpoints != null ? local.advanced_settings.storage_private_endpoints : false))
      config = local.resources.virtual_network
    }
  }
  
  # Generate common tags
  common_tags = merge(
    local.customer_info.tags,
    {
      deployment_date = timestamp()
      terraform_managed = "true"
    }
  )
}

# Resource Group (Foundation)
resource "azurerm_resource_group" "main" {
  count = local.resolved_resources.resource_group.enabled ? 1 : 0
  
  name     = local.resolved_resources.resource_group.config.name
  location = local.customer_info.location
  tags     = local.common_tags
}

# Storage Account (Conditional)
resource "azurerm_storage_account" "main" {
  count = local.resolved_resources.storage_account.enabled ? 1 : 0
  
  name                     = local.resolved_resources.storage_account.config.name
  resource_group_name      = azurerm_resource_group.main[0].name
  location                 = azurerm_resource_group.main[0].location
  account_tier             = local.resolved_resources.storage_account.config.account_tier
  account_replication_type = local.resolved_resources.storage_account.config.account_replication_type
  
  # Security settings
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  
  tags = local.common_tags

  depends_on = [azurerm_resource_group.main]
}

# Storage Containers (Conditional)
resource "azurerm_storage_container" "containers" {
  count = local.resolved_resources.storage_account.enabled ? length(local.resolved_resources.storage_account.config.containers) : 0
  
  name                  = local.resolved_resources.storage_account.config.containers[count.index]
  storage_account_name  = azurerm_storage_account.main[0].name
  container_access_type = "private"

  depends_on = [azurerm_storage_account.main]
}

# Key Vault (Conditional)
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  count = local.resolved_resources.key_vault.enabled ? 1 : 0
  
  name                = local.resolved_resources.key_vault.config.name
  location            = azurerm_resource_group.main[0].location
  resource_group_name = azurerm_resource_group.main[0].name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  
  sku_name = local.resolved_resources.key_vault.config.sku_name
  
  soft_delete_retention_days = local.resolved_resources.key_vault.config.soft_delete_retention_days
  purge_protection_enabled   = false  # For demo purposes
  
  # Default access policy for current service principal
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    
    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"
    ]
    
    key_permissions = [
      "Get", "List", "Create", "Delete", "Recover", "Backup", "Restore"
    ]
    
    certificate_permissions = [
      "Get", "List", "Create", "Delete", "Recover", "Backup", "Restore"
    ]
  }
  
  tags = local.common_tags

  depends_on = [azurerm_resource_group.main]
}

# Key Vault Secrets (Conditional)
resource "azurerm_key_vault_secret" "secrets" {
  count = local.resolved_resources.key_vault.enabled ? length(local.resolved_resources.key_vault.config.secrets) : 0
  
  name         = local.resolved_resources.key_vault.config.secrets[count.index].name
  value        = local.resolved_resources.key_vault.config.secrets[count.index].value
  key_vault_id = azurerm_key_vault.main[0].id
  
  tags = local.common_tags

  depends_on = [azurerm_key_vault.main]
}

# Virtual Network (Conditional - for advanced scenarios)
resource "azurerm_virtual_network" "main" {
  count = local.resolved_resources.virtual_network.enabled ? 1 : 0
  
  name                = local.resolved_resources.virtual_network.config.name
  address_space       = local.resolved_resources.virtual_network.config.address_space
  location            = azurerm_resource_group.main[0].location
  resource_group_name = azurerm_resource_group.main[0].name
  
  tags = local.common_tags

  depends_on = [azurerm_resource_group.main]
}

# Subnets (Conditional)
resource "azurerm_subnet" "subnets" {
  count = local.resolved_resources.virtual_network.enabled ? length(try(local.resolved_resources.virtual_network.config.subnets, [])) : 0
  
  name                 = local.resolved_resources.virtual_network.config.subnets[count.index].name
  resource_group_name  = azurerm_resource_group.main[0].name
  virtual_network_name = azurerm_virtual_network.main[0].name
  address_prefixes     = [local.resolved_resources.virtual_network.config.subnets[count.index].address_prefix]

  depends_on = [azurerm_virtual_network.main]
}