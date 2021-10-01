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

locals {
    controller                          = var.cluster.primary ? kubernetes_service.boundary[0].status[0].load_balancer[0].ingress[0].ip : var.controller
}

resource "kubernetes_service" "boundary_worker" {
    metadata {
        name                            = "boundary-worker"
        namespace                       = kubernetes_namespace.boundary.metadata[0].name
        labels                          = {
            app                         = "boundary-worker"
        }
    }

    spec {
        type                            = "ClusterIP"
        selector                        = {
            app                         = "boundary-worker"
        }
        port {
            name                        = "data"
            port                        = 9202
            target_port                 = 9202
        }
    }
    depends_on                          = [kubernetes_deployment.boundary]
}

resource "kubernetes_service_account" "boundary_worker" {
    automount_service_account_token     = true
    metadata {
        name                            = "boundary-worker"
        namespace                       = kubernetes_namespace.boundary.metadata[0].name
    }
    depends_on                          = [kubernetes_service.boundary_worker]
}

resource "kubernetes_config_map" "boundary_worker" {
    metadata {
        name                            = "boundary-worker-config"
        namespace                       = kubernetes_namespace.boundary.metadata[0].name
    }

    data                                = {
        "boundary.hcl"                  = <<EOF
disable_mlock = true

worker {
	name = "boundary-worker"
	description = "A Boundary Worker for Kubernetes"
    controllers = ["${local.controller}"]
}

listener "tcp" {
	address = "0.0.0.0"
	purpose = "proxy"
	tls_disable = true
}

kms "aead" {
	purpose = "worker-auth"
	aead_type = "aes-gcm"
	key = "8fZBjCUfN0TzjEGLQldGY4+iE9AkOvCfjh7+p0GtRBQ="
	key_id = "global_worker-auth"
}

EOF
    }
    depends_on = [kubernetes_service_account.boundary_worker]
}

resource "kubernetes_deployment" "boundary_worker" {
    metadata {
        name                            = "boundary-worker"
        namespace                       = kubernetes_namespace.boundary.metadata[0].name
        labels                          = {
            app                         = "boundary"
        }
    }

    spec {
        replicas                        = 1
        selector {
            match_labels                = {
                app                     = "boundary-worker"
            }
        }

        template {
            metadata {
                labels = {
                    app                 = "boundary-worker"
                    service             = "boundary-worker"
                }
            }

            spec {
                service_account_name    = "boundary-worker"
                volume {
                    name                = "boundary-worker-config"
                    config_map {
                        name            = "boundary-worker-config"
                    }
                }

                container {
                    image               = "hashicorp/boundary:latest"
                    name                = "boundary-worker"

                    volume_mount {
                        name            = "boundary-worker-config"
                        mount_path      = "/boundary"
                        read_only       = true
                    }

                    command             = ["/bin/sh", "-c"]
                    args                = ["boundary server -config /boundary/boundary.hcl"]

                    env {
                        name            = "HOSTNAME"
                        value           = "boundary-worker"
                    }

                    port {
                        container_port  = 9202
                    }
                }
            }
        }
    }
    depends_on = [kubernetes_config_map.boundary_worker]
}