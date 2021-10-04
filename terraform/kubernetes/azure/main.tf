////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Repo:           hashistack-kubernetes
//  File Name:      kubernetes/azure/aks/main.tf
//  Author:         Patrick Gryzan
//  Company:        Hashicorp
//  Date:           September 2021
//  Description:    This is the main execution file
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Environment
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
terraform {
    required_version                = ">= 1.0.6"
}

data "terraform_remote_state" "global" {
    backend                     = "remote"
    config                      = {
        organization            = var.global.organization
        workspaces              = {
            name                = var.global.workspace
        }
    }
}

provider "azurerm" {
    subscription_id             = data.terraform_remote_state.global.outputs.azure.subscription_id
    tenant_id                   = data.terraform_remote_state.global.outputs.azure.tenant_id
    client_id                   = data.terraform_remote_state.global.outputs.azure.client_id
    client_secret               = data.terraform_remote_state.global.outputs.azure.client_secret
    features {}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  AKS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module "aks" {
    source                      = "../../modules/terraform-azure-aks"
    info                        = data.terraform_remote_state.global.outputs.info
    azure                       = data.terraform_remote_state.global.outputs.azure
    cluster                     = var.cluster
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Configuration
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
provider "kubernetes" {
    host                            = module.aks.cluster.endpoint
    client_certificate              = module.aks.cluster.client_certificate
    client_key                      = module.aks.cluster.client_key
    cluster_ca_certificate          = module.aks.cluster.cluster_ca_certificate
}

provider "helm" {
    kubernetes {
        host                        = module.aks.cluster.endpoint
        client_certificate          = module.aks.cluster.client_certificate
        client_key                  = module.aks.cluster.client_key
        cluster_ca_certificate      = module.aks.cluster.cluster_ca_certificate
    }
}

data "terraform_remote_state" "primary" {
    count                       = var.cluster.primary ? 0 : 1
    backend                     = "remote"
    config                      = {
        organization            = var.global.organization
        workspaces              = {
            name                = var.consul.federated_workspace
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Consul
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module "consul" {
    source                      = "../../modules/terraform-helm-consul"
    cluster                     = var.cluster
    replicas                    = var.consul.replicas
    consul_version              = var.consul.version
    license                     = data.terraform_remote_state.global.outputs.consul.license
    federation_token            = var.cluster.primary ? null : data.terraform_remote_state.primary[0].outputs.consul.federation_token
    depends_on                  = [module.aks]
}

provider "consul" {
    datacenter                  = var.cluster.name
    address                     = "https://${module.consul.ui}:443"
    scheme                      = "https"
    insecure_https              = true
    token                       = var.cluster.primary ? module.consul.acl_token : var.acl_token
}

module "consul_config" {
    source                      = "../../modules/terraform-consul-config"
    cluster                     = var.cluster
    depends_on                  = [module.consul]
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Vault
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module "vault" {
    source                      = "../../modules/terraform-helm-vault"
    cluster                     = var.cluster
    gcp                         = data.terraform_remote_state.global.outputs.gcp
    replicas                    = var.vault.replicas
    vault_version               = var.vault.version
    license                     = data.terraform_remote_state.global.outputs.vault.license
    depends_on                  = [module.consul]
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Boundary
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module "boundary" {
    source                      = "../../modules/terraform-kubernetes-boundary"
    cluster                     = var.cluster
    depends_on                  = [module.vault]
}

provider "boundary" {
    addr                        = "http://${module.boundary.endpoint}:9200"
    recovery_kms_hcl            = module.boundary.recovery_kms_hcl
}

module "boundary_config" {
    count                       = var.cluster.primary ? 1 : 0
    source                      = "../../modules/terraform-boundary-config"
    depends_on                  = [module.boundary]
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  HashiCups
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module "hashicups" {
    count                       = var.deploy_hashicups ? 1 : 0
    source                      = "app.terraform.io/pgryzan/hashicups/kubernetes"
    frontend_version            = var.frontend_version
    create_traffic              = var.create_traffic
    create_intentions           = var.create_intentions
    create_routing              = var.create_routing
    failover_datacenters        = var.failover_datacenters
}