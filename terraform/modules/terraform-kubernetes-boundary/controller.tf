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

resource "kubernetes_service" "boundary" {
    count                               = var.cluster.primary ? 1 : 0
    metadata {
        name                            = "boundary"
        namespace                       = kubernetes_namespace.boundary.metadata[0].name
        labels                          = {
            app                         = "boundary"
        }
    }

    spec {
        type                            = "LoadBalancer"
        selector                        = {
            app                         = "boundary"
        }
        port {
            name                        = "api"
            port                        = 9200
            target_port                 = 9200
        }
        port {
            name                        = "cluster"
            port                        = 9201
            target_port                 = 9201
        }
    }
    depends_on                          = [kubernetes_deployment.postgres]
}

resource "kubernetes_service_account" "boundary" {
    count                               = var.cluster.primary ? 1 : 0
    automount_service_account_token     = true
    metadata {
        name                            = "boundary"
        namespace                       = kubernetes_namespace.boundary.metadata[0].name
    }
    depends_on                          = [kubernetes_service.boundary]
}

resource "kubernetes_config_map" "boundary" {
    count                               = var.cluster.primary ? 1 : 0
    metadata {
        name                            = "boundary-config"
        namespace                       = kubernetes_namespace.boundary.metadata[0].name
    }

    data                                = {
        "boundary.hcl"                  = <<EOF
disable_mlock = true

controller {
	name = "boundary-controller"
	description = "A Boundary Controller for Kubernetes"
	database {
		url = "env://BOUNDARY_PG_URL"
	}
}

listener "tcp" {
	address = "0.0.0.0"
	purpose = "api"
	tls_disable = true
    cors_enabled = true
	cors_allowed_origins = ["*"]
}

listener "tcp" {
	address = "0.0.0.0"
	purpose = "cluster"
	tls_disable = true
}

kms "aead" {
	purpose = "root"
	aead_type = "aes-gcm"
	key = "sP1fnF5Xz85RrXyELHFeZg9Ad2qt4Z4bgNHVGtD6ung="
	key_id = "global_root"
}

kms "aead" {
	purpose = "worker-auth"
	aead_type = "aes-gcm"
	key = "8fZBjCUfN0TzjEGLQldGY4+iE9AkOvCfjh7+p0GtRBQ="
	key_id = "global_worker-auth"
}

kms "aead" {
	purpose = "recovery"
	aead_type = "aes-gcm"
	key = "8fZBjCUfN0TzjEGLQldGY4+iE9AkOvCfjh7+p0GtRBQ="
	key_id = "global_recovery"
}
EOF
    }
    depends_on = [kubernetes_service_account.boundary]
}

resource "kubernetes_deployment" "boundary" {
    count                               = var.cluster.primary ? 1 : 0
    metadata {
        name                            = "boundary"
        namespace                       = kubernetes_namespace.boundary.metadata[0].name
        labels                          = {
            app                         = "boundary"
        }
    }

    spec {
        replicas                        = 1
        selector {
            match_labels                = {
                app                     = "boundary"
            }
        }

        template {
            metadata {
                labels = {
                    app                 = "boundary"
                    service             = "boundary"
                }
            }

            spec {
                service_account_name    = "boundary"
                volume {
                    name                = "boundary-config"
                    config_map {
                        name            = "boundary-config"
                    }
                }

                init_container {
                    name                = "boundary-init"
                    image               = "hashicorp/boundary:latest"
                    command             = ["/bin/sh", "-c"]
                    args                = ["boundary database init -config /boundary/boundary.hcl"]

                    volume_mount {
                        name            = "boundary-config"
                        mount_path      = "/boundary"
                        read_only       = true
                    }

                    env {
                        name            = "BOUNDARY_PG_URL"
                        value           = "postgresql://postgres:postgres@boundary-postgres:5432/boundary?sslmode=disable"
                    }

                    env {
                        name            = "HOSTNAME"
                        value           = "boundary"
                    }
                }

                container {
                    image               = "hashicorp/boundary:latest"
                    name                = "boundary"

                    volume_mount {
                        name            = "boundary-config"
                        mount_path      = "/boundary"
                        read_only       = true
                    }

                    command             = ["/bin/sh", "-c"]
                    args                = ["boundary server -config /boundary/boundary.hcl"]

                    env {
                        name            = "BOUNDARY_PG_URL"
                        value           = "postgresql://postgres:postgres@boundary-postgres:5432/boundary?sslmode=disable"
                    }

                    env {
                        name            = "HOSTNAME"
                        value           = "boundary"
                    }

                    port {
                        container_port  = 9200
                    }
                    port {
                        container_port  = 9201
                    }
                }
            }
        }
    }
    depends_on = [kubernetes_config_map.boundary]
}