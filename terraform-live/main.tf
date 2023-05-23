locals {
  acr_name = replace("${var.app_name}-${var.environment}-acr", "-", "")
  aks_name = "${var.app_name}-${var.environment}-aks"
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
    vm_size    = "Standard_D2_v2"
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

# output "client_certificate" {
#   value     = azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate
#   sensitive = true
# }

# output "kube_config" {
#   value = azurerm_kubernetes_cluster.aks.kube_config_raw

#   sensitive = true
# }