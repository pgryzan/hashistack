////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Repo:           hashistack
//  File Name:      kubernetes/aws/eks/main.tf
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
    required_version            = ">= 1.0.6"
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

provider "aws" {
    region                      = var.cluster.region
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  EKS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module "eks" {
    source                      = "../../modules/terraform-aws-eks"
    info                        = data.terraform_remote_state.global.outputs.info
    cluster                     = var.cluster
    worker_groups               = var.worker_groups
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Configuration
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
provider "kubernetes" {
    host                        = module.eks.cluster.endpoint
    token                       = module.eks.cluster.token
    cluster_ca_certificate      = module.eks.cluster.cluster_ca_certificate
}

provider "helm" {
    kubernetes {
        host                    = module.eks.cluster.endpoint
        token                   = module.eks.cluster.token
        cluster_ca_certificate  = module.eks.cluster.cluster_ca_certificate
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
    depends_on                  = [module.eks]
}

provider "consul" {
    datacenter                  = var.cluster.name
    address                     = "https://${module.consul.ui}:443"
    scheme                      = "https"
    insecure_https              = true
    token                       = module.consul.acl_token
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