////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Repo:           hashistack
//  File Name:      kubernetes/modules/terraform-kubernetes-boundary/redis.tf
//  Author:         Patrick Gryzan
//  Company:        Hashicorp
//  Date:           September 2021
//  Description:    This is the postgres execution file for boundary module
//                  https://github.com/hashicorp/boundary-reference-architecture/tree/main/deployment/kube/kubernetes
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

resource "kubernetes_service" "redis" {
    metadata {
        name                            = "redis"
        namespace                       = kubernetes_namespace.hashicups.metadata[0].name
        labels                          = {
            app                         = var.redis.name
        }
    }
    spec {
        selector                        = {
            app                         = var.redis.name
        }
        port {
            port                        = var.redis.port
            target_port                 = var.redis.port
        }
        type                            = "ClusterIP"
    }
    depends_on                          = [kubernetes_namespace.hashicups]
}

resource "kubernetes_service_account" "redis" {
    automount_service_account_token     = true
    metadata {
        name                            = var.redis.name
        namespace                       = kubernetes_namespace.hashicups.metadata[0].name
    }
    depends_on                          = [kubernetes_service.redis]
}

resource "kubernetes_deployment" "redis" {
    metadata {
        name                            = var.redis.name
        namespace                       = kubernetes_namespace.hashicups.metadata[0].name
    }
    spec {
        replicas                        = var.redis.replicas
        selector {
            match_labels                = {
                app                     = var.redis.name
                service                 = var.redis.name
            }
        }
        template {
            metadata {
                labels                  = {
                    app                 = var.redis.name
                    service             = var.redis.name
                }
                annotations             = {
                    "prometheus.io/port" = "9102"
                    "prometheus.io/scrape" = "true"
                    "consul.hashicorp.com/connect-inject" = "true"
                }
            }
            spec {
                service_account_name    = var.redis.name
                container {
                    name                = var.redis.name
                    image               = var.redis.image
                    port {
                        container_port  = var.redis.port
                    }
                }
            }
        }
    }
    depends_on                          = [kubernetes_service_account.redis]
}