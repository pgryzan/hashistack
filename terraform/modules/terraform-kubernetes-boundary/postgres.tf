////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Repo:           hashistack
//  File Name:      kubernetes/modules/terraform-kubernetes-boundary/postgres.tf
//  Author:         Patrick Gryzan
//  Company:        Hashicorp
//  Date:           September 2021
//  Description:    This is the postgres execution file for boundary module
//                  https://github.com/hashicorp/boundary-reference-architecture/tree/main/deployment/kube/kubernetes
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

resource "kubernetes_service" "boundary_postgres" {
    count                               = var.cluster.primary ? 1 : 0
    metadata {
        name                            = "boundary-postgres"
        namespace                       = kubernetes_namespace.boundary.metadata[0].name
        labels                          = {
            app                         = "boundary-postgres"
        }
    }

    spec {
        type = "ClusterIP"
        selector                        = {
            app                         = "boundary-postgres"
        }

        port {
            port                        = 5432
            target_port                 = 5432
        }
    }
    depends_on                          = [kubernetes_namespace.boundary]
}

resource "kubernetes_service_account" "boundary_postgres" {
    count                               = var.cluster.primary ? 1 : 0
    automount_service_account_token     = true
    metadata {
        name                            = "boundary-postgres"
        namespace                       = kubernetes_namespace.boundary.metadata[0].name
    }
    depends_on                          = [kubernetes_service.boundary_postgres]
}


resource "kubernetes_deployment" "postgres" {
    count                               = var.cluster.primary ? 1 : 0
    metadata {
        name                            = "boundary-postgres"
        namespace                       = kubernetes_namespace.boundary.metadata[0].name
        labels                          = {
            app                         = "boundary-postgres"
        }
    }
    spec {
        replicas = 1
        selector {
            match_labels                = {
                app                     = "boundary-postgres"
            }
        }
        template {
            metadata {
                labels = {
                    service             = "boundary-postgres"
                    app                 = "boundary-postgres"
                }
            }
            spec {
                service_account_name    = "boundary-postgres"
                container {
                    name                = "boundary-postgres"
                    image               = "postgres"
                    env {
                        name            = "POSTGRES_DB"
                        value           = "boundary"
                    }
                    env {
                        name            = "POSTGRES_USER"
                        value           = "postgres"
                    }
                    env {
                        name            = "POSTGRES_PASSWORD"
                        value           = "postgres"
                    }
                    port {
                        container_port  = 5432
                    }
                    liveness_probe {
                        exec {
                            command     = ["psql", "-w", "-U", "postgres", "-d", "boundary", "-c", "SELECT", "1"]
                        }
                    }
                }
            }
        }
    }
    depends_on                          = [kubernetes_service_account.boundary_postgres]
}