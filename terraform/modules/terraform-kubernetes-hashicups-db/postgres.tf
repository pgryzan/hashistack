////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Repo:           hashistack-kubernetes
//  File Name:      modules/hashicups/main.tf
//  Author:         Patrick Gryzan
//  Company:        Hashicorp
//  Date:           September 2021
//  Description:    This is the postgres execution file for hashicups module
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

resource "kubernetes_service" "postgres" {
    metadata {
        name                            = var.postgres.name
        namespace                       = kubernetes_namespace.hashicups.metadata[0].name
        labels                          = {
            app                         = var.postgres.name
        }
    }
    spec {
        selector                        = {
            app                         = var.postgres.name
        }
        port {
            port                        = var.postgres.port
            target_port                 = var.postgres.port
        }
        type                            = "ClusterIP"
    }
    depends_on                          = [kubernetes_namespace.hashicups]
}

resource "kubernetes_service_account" "postgres" {
    automount_service_account_token     = true
    metadata {
        name                            = var.postgres.name
        namespace                       = kubernetes_namespace.hashicups.metadata[0].name
    }
    depends_on                          = [kubernetes_service.postgres]
}

resource "kubernetes_deployment" "postgres" {
    metadata {
        name                            = var.postgres.name
        namespace                       = kubernetes_namespace.hashicups.metadata[0].name
    }
    spec {
        replicas                        = var.postgres.replicas
        selector {
            match_labels                = {
                app                     = var.postgres.name
                service                 = var.postgres.name
            }
        }
        template {
            metadata {
                labels                  = {
                    app                 = var.postgres.name
                    service             = var.postgres.name
                }
                annotations             = {
                    "prometheus.io/port" = "9102"
                    "prometheus.io/scrape" = "true"
                    "consul.hashicorp.com/connect-inject" = "true"
                }
            }
            spec {
                service_account_name    = var.postgres.name
                container {
                    name                = var.postgres.name
                    image               = var.postgres.image
                    args                = ["-c", "listen_addresses=127.0.0.1"]
                    env {
                        name            = "POSTGRES_DB"
                        value           = "products"
                    }
                    env {
                        name            = "POSTGRES_USER"
                        value           = "postgres"
                    }
                    env {
                        name            = "POSTGRES_PASSWORD"
                        value           = "password"
                    }
                    port {
                        container_port  = var.postgres.port
                    }
                    volume_mount {
                        mount_path      = "/var/lib/postgresql/data"
                        name            = "pgdata"
                    }
                }
                volume {
                    name                = "pgdata"
                    empty_dir {}
                }
            }
        }
    }
    depends_on                          = [kubernetes_service_account.postgres]
}