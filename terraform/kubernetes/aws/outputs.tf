////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Repo:           hashistack
//  File Name:      kubernetes/aws/eks/outputs.tf
//  Author:         Patrick Gryzan
//  Company:        Hashicorp
//  Date:           September 2021
//  Description:    This is the outputs file
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

output "cluster" {
    sensitive                   = true
    value                       = {
        id                      = module.eks.cluster.id
        endpoint                = module.eks.cluster.endpoint
        cluster_ca_certificate  = module.eks.cluster.cluster_ca_certificate
        token                   = module.eks.cluster.token
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