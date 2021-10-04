////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Repo:           hashistack-kubernetes
//  File Name:      kubernetes/azure/aks/outputs.tf
//  Author:         Patrick Gryzan
//  Company:        Hashicorp
//  Date:           September 2021
//  Description:    This is the outputs file
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

output "cluster" {
    sensitive                   = true
    value                       = {
        endpoint                = module.aks.cluster.endpoint
        client_certificate      = module.aks.cluster.client_certificate
        client_key              = module.aks.cluster.client_key
        cluster_ca_certificate  = module.aks.cluster.cluster_ca_certificate
    }
}

output "consul" {
    sensitive                   = true
    value                       = {
        federation_token        = module.consul.federation_token
        dns                     = module.consul.dns
        ingress_gateway         = module.consul.ingress_gateway
        mesh_gateway            = module.consul.mesh_gateway
        ui                      = module.consul.ui
        acl_token               = module.consul.acl_token
    }
}

output "boundary" {
    sensitive                   = true
    value                       = {
        endpoint                = module.boundary.endpoint
        recovery_kms_hcl        = module.boundary.recovery_kms_hcl
        scope_id                = var.cluster.primary ? module.boundary_config[0].scope_id : ""
    }
}