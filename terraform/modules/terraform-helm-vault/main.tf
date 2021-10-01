////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Repo:           hashistack
//  File Name:      modules/terraform-helm-vault/main.tf
//  Author:         Patrick Gryzan
//  Company:        Hashicorp
//  Date:           August 2021
//  Description:    This is the main execution file for vault module
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Environment
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
terraform {
    required_version            = ">= 1.0.6"
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Kubernetes
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
resource "kubernetes_namespace" "vault" {
    metadata {
        name                    = "vault"
    }
}

resource "kubernetes_secret" "vault-license" {
    metadata {
        name                    = "vault-license"
        namespace               = kubernetes_namespace.vault.metadata[0].name
    }
    data = {
        "license"               = var.license
    }
    depends_on                  = [
        kubernetes_namespace.vault
    ]
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Helm
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
data "template_file" "config" {
    template                    = "${file("${path.module}/vault-values.yaml")}"
    vars                        = {
        vault_version           = var.vault_version
        replicas                = var.replicas
    }
}

resource "helm_release" "vault" {
    name                        = "vault"
    repository                  = "https://helm.releases.hashicorp.com"
    chart                       = "vault"
    namespace                   = kubernetes_namespace.vault.metadata[0].name
    
    values                      = [
        data.template_file.config.rendered
    ]

    depends_on                  = [
        kubernetes_secret.vault-license
    ]
}

data "kubernetes_secret" "vault-license" {
    metadata {
        name                    = "vault-license"
        namespace               = kubernetes_namespace.vault.metadata[0].name
    }
    depends_on                  = [
        helm_release.vault
    ]
}

data "kubernetes_service" "vault-ui" {
    metadata {
        name                    = "vault-ui"
        namespace               = kubernetes_namespace.vault.metadata[0].name
    }
    depends_on                  = [
        helm_release.vault
    ]
}