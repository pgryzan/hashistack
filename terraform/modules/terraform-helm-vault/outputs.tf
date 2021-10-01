////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Repo:           hashistack
//  File Name:      modules/terraform-helm-vault/outputs.tf
//  Author:         Patrick Gryzan
//  Company:        Hashicorp
//  Date:           August 2021
//  Description:    This is the outputs file for the vault module
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

output "replicas" {
    value       = var.replicas
}

output "version" {
    value       = var.vault_version
}

output "license" {
    value       = data.kubernetes_secret.vault-license.data.license
}

output "ui" {
    value       = data.kubernetes_service.vault-ui.status[0].load_balancer[0].ingress[0].ip
}