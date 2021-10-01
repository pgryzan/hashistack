////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Repo:           hashistack
//  File Name:      kubernetes/modules/terraform-helm-consul/outputs.tf
//  Author:         Patrick Gryzan
//  Company:        Hashicorp
//  Date:           September 2021
//  Description:    This is the outputs file for the consul module
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

output "replicas" {
    value       = var.replicas
}

output "version" {
    value       = var.consul_version
}

output "license" {
    value       = data.kubernetes_secret.consul-license.data.key
}

output "federation_token" {
    value       = data.kubernetes_secret.consul-federation.data
}

output "acl_token" {
    value       = var.cluster.primary ? data.kubernetes_secret.consul-bootstrap-acl-token[0].data.token : ""
}

output "dns" {
    value       = data.kubernetes_service.consul-dns.spec[0].cluster_ip
}

output "ingress_gateway" {
    value       = data.kubernetes_service.consul-ingress-gateway.status[0].load_balancer[0].ingress[0].ip
}

output "mesh_gateway" {
    value       = data.kubernetes_service.consul-mesh-gateway.status[0].load_balancer[0].ingress[0].ip
}

output "ui" {
    value       = data.kubernetes_service.consul-ui.status[0].load_balancer[0].ingress[0].ip
}