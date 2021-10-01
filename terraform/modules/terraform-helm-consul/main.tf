////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Repo:           hashistack
//  File Name:      kubernetes/modules/terraform-helm-consul/main.tf
//  Author:         Patrick Gryzan
//  Company:        Hashicorp
//  Date:           September 2021
//  Description:    This is the main execution file for consul module
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
resource "kubernetes_namespace" "consul" {
    metadata {
        name                    = "consul"
    }
}

resource "kubernetes_secret" "consul-license" {
    metadata {
        name                    = "consul-license"
        namespace               = kubernetes_namespace.consul.metadata[0].name
    }
    data = {
        "key"                   = var.license
    }
    depends_on                  = [
        kubernetes_namespace.consul
    ]
}

resource "kubernetes_secret" "consul-federation" {
    metadata {
        name                    = "consul-federation"
        namespace               = kubernetes_namespace.consul.metadata[0].name
    }
    data                        = var.federation_token
    depends_on                  = [
        kubernetes_secret.consul-license
    ]
}

resource "kubernetes_secret" "consul-gossip-encryption-key" {
    metadata {
        name                    = "consul-gossip-encryption-key"
        namespace               = kubernetes_namespace.consul.metadata[0].name
    }
    data                        = {
        "key"                   = var.gossip_encryption_key
    }
    depends_on                  = [
        kubernetes_secret.consul-federation
    ]
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Helm
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
data "template_file" "config" {
    template                    = "${file("${path.module}/consul-values.yaml")}"
    vars                        = {
        datacenter              = var.cluster.name
        primary                 = var.cluster.primary
        replicas                = var.replicas
        consul_version          = var.consul_version
    }
}

resource "helm_release" "consul" {
    name                        = "consul"
    repository                  = "https://helm.releases.hashicorp.com"
    chart                       = "consul"
    namespace                   = kubernetes_namespace.consul.metadata[0].name
    values                      = [
        data.template_file.config.rendered
    ]
    depends_on                  = [
        kubernetes_secret.consul-gossip-encryption-key
    ]
}

data "kubernetes_secret" "consul-license" {
    metadata {
        name                    = "consul-license"
        namespace               = kubernetes_namespace.consul.metadata[0].name
    }
    depends_on                  = [
        helm_release.consul
    ]
}

data "kubernetes_secret" "consul-federation" {
    metadata {
        name                    = "consul-federation"
        namespace               = kubernetes_namespace.consul.metadata[0].name
    }
    depends_on                  = [
        helm_release.consul
    ]
}

data "kubernetes_secret" "consul-bootstrap-acl-token" {
    count                       = var.cluster.primary ? 1 : 0
    metadata {
        name                    = "consul-bootstrap-acl-token"
        namespace               = kubernetes_namespace.consul.metadata[0].name
    }
    depends_on                  = [
        helm_release.consul
    ]
}

data "kubernetes_service" "consul-dns" {
    metadata {
        name                    = "consul-dns"
        namespace               = kubernetes_namespace.consul.metadata[0].name
    }
    depends_on                  = [
        helm_release.consul
    ]
}

data "kubernetes_service" "consul-ingress-gateway" {
    metadata {
        name                    = "consul-ingress-gateway"
        namespace               = kubernetes_namespace.consul.metadata[0].name
    }
    depends_on                  = [
        helm_release.consul
    ]
}

data "kubernetes_service" "consul-mesh-gateway" {
    metadata {
        name                    = "consul-mesh-gateway"
        namespace               = kubernetes_namespace.consul.metadata[0].name
    }
    depends_on                  = [
        helm_release.consul
    ]
}

data "kubernetes_service" "consul-ui" {
    metadata {
        name                    = "consul-ui"
        namespace               = kubernetes_namespace.consul.metadata[0].name
    }
    depends_on                  = [
        helm_release.consul
    ]
}