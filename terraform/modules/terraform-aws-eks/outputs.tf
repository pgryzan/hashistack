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
        id                      = module.eks.cluster_id
        endpoint                = module.eks.cluster_endpoint
        token                   = data.aws_eks_cluster_auth.cluster.token
        cluster_ca_certificate  = local.cluster_ca_certificate
    }
}