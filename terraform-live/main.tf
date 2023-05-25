locals {
  acr_name = replace("${var.app_name}-${var.environment}-acr", "-", "")
  aks_name = "${var.app_name}-${var.environment}-aks"
  kv_name  = "${var.app_name}-${var.environment}-kv"
}

resource "azurerm_resource_group" "resource_group" {
  name     = "${var.app_name}-${var.environment}-rg"
  location = var.location
}

module "acr" {
  source = "../terraform-modules/azure-container-registry"
  acr_name = local.acr_name
  resource_group_name = azurerm_resource_group.resource_group.name
  location = var.location
  acr_sku = "Basic"
  admin_enabled = true
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = local.aks_name
  location            = var.location
  resource_group_name = azurerm_resource_group.resource_group.name
  dns_prefix          = local.aks_name

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_B2ms"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_role_assignment" "aks_acr_role" {
  depends_on = [ module.acr, azurerm_kubernetes_cluster.aks ]
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = module.acr.azure_container_registry.id
  skip_service_principal_aad_check = true
}

resource "azurerm_key_vault" "kv" {
  name                       = local.kv_name
  location                   = var.location
  resource_group_name        = azurerm_resource_group.resource_group.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "premium"
  soft_delete_retention_days = 7

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Set",
      "Get",
      "Delete",
      "Purge",
      "Recover"
    ]
  }
}

resource "azurerm_key_vault_secret" "kv_secret_acr_server" {
  name         = "acrLoginServer"
  value        = module.acr.azure_container_registry.login_server
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "kv_secret_acr_username" {
  name         = "acrUsername"
  value        = module.acr.azure_container_registry.admin_username
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "kv_secret_acr_password" {
  name         = "acrPassword"
  value        = module.acr.azure_container_registry.admin_password
  key_vault_id = azurerm_key_vault.kv.id
}