////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Repo:           hashistack
//  File Name:      kubernetes/modules/terraform-kubernetes-boundary/boundary.tf
//  Author:         Patrick Gryzan
//  Company:        Hashicorp
//  Date:           September 2021
//  Description:    This is the boundary execution file for boundary module
//                  https://github.com/hashicorp/boundary-reference-architecture/tree/main/deployment/kube/kubernetes
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

output "scope_id" {
    value       = boundary_scope.org.id
}