////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Repo:           hashistack
//  File Name:      modules/terraform-kubernetes-config/main.tf
//  Author:         Patrick Gryzan
//  Company:        Hashicorp
//  Date:           September 2021
//  Description:    This is the main execution file for config module
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Environment
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
terraform {
    required_version        = ">= 1.0.6"
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Consul
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// resource "kubernetes_manifest" "kube_dns" {
//     manifest                = {
//         "apiVersion"        = "v1"
//         "kind"              = "ConfigMap"
//         "metadata"          = {
//             "labels"        = {
//                 "addonmanager.kubernetes.io/mode" = "EnsureExists"
//             }
//             "name"          = "kube-dns"
//             "namespace"     = "kube-system"
//         }
//         "data" = {
//             "stubDomains"   = "{\"consul\": [\"${var.consul_dns}\"]}"
//         }
//     }
// }

resource "consul_config_entry" "proxy_defaults" {
    count                   = var.cluster.primary ? 1 : 0
    kind                    = "proxy-defaults"
    name                    = "global"
    config_json             = jsonencode({
        MeshGateway         = {
            Mode            = "local"
        }
    })
}

resource "consul_acl_policy" "service_policy" {
    count                   = var.cluster.primary ? 1 : 0
    name                    = "service_policy"
    rules                   = <<-RULE
service_prefix "" {
    policy = "write"
}
RULE
}

// apiVersion: consul.hashicorp.com/v1alpha1
// kind: ProxyDefaults
// metadata:
//   name: global
// spec:
//   meshGateway:
//     mode: 'local'

// resource "kubernetes_manifest" "proxy_defaults" {
//     manifest                = {
//         "apiVersion"        = "consul.hashicorp.com/v1alpha1"
//         "kind"              = "ProxyDefaults"
//         "metadata"          = {
//             "name"          = "global"
//             "namespace"     = "default"
//             "finalizers"    = ["finalizers.consul.hashicorp.com"]
//         }
//         "spec"              = {
//             "meshGateway"   = {
//                 "mode"      = "local"
//             }
//         }
//     }
//     depends_on              = [kubernetes_manifest.kube_dns]
// }