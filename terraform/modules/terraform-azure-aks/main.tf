////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Repo:           hashistack
//  File Name:      tfc/kubernetes/google/main.tf
//  Author:         Patrick Gryzan
//  Company:        Hashicorp
//  Date:           September 2021
//  Description:    This is the main execution file
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Environment
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
terraform {
    required_version            = ">= 1.0.6"
}

locals {
    prefix                      = "${var.info.name}-${var.cluster.name}"
    client_certificate          = base64decode(azurerm_kubernetes_cluster.cluster.kube_config[0].client_certificate)
    client_key                  = base64decode(azurerm_kubernetes_cluster.cluster.kube_config[0].client_key)
    cluster_ca_certificate      = base64decode(azurerm_kubernetes_cluster.cluster.kube_config[0].cluster_ca_certificate)
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Resource Group
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
resource "azurerm_resource_group" "cluster" {
    name                            = "${local.prefix}"
    location                        = var.cluster.region
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  AKS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
resource "azurerm_kubernetes_cluster" "cluster" {
    name                            = "${local.prefix}-aks"
    location                        = azurerm_resource_group.cluster.location
    resource_group_name             = azurerm_resource_group.cluster.name
    dns_prefix                      = "${local.prefix}-k8s"
    automatic_channel_upgrade       = "stable"

    default_node_pool {
        name                        = "default"
        node_count                  = var.cluster.node_count
        vm_size                     = var.cluster.machine_type
    }

    service_principal {
        client_id                   = var.azure.client_id
        client_secret               = var.azure.client_secret
    }

    role_based_access_control {
        enabled                     = true
    }
}