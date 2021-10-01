 ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Repo:           hashistack
//  File Name:      tfc/kubernetes/google/outputs.tf
//  Author:         Patrick Gryzan
//  Company:        Hashicorp
//  Date:           September 2021
//  Description:    This is the outputs file
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

output "cluster" {
    sensitive                   = true
    value                       = {
        endpoint                = azurerm_kubernetes_cluster.cluster.kube_config[0].host
        client_certificate      = local.client_certificate
        client_key              = local.client_key
        cluster_ca_certificate  = local.cluster_ca_certificate
    }
}