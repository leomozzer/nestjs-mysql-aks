resource "random_string" "random" {
  length  = 7
  special = false
  upper   = false
}

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
    Environment = "Production"
  }
}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate
  sensitive = true
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.aks.kube_config_raw

  sensitive = true
}