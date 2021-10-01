////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Repo:           hashistack
//  File Name:      tfc/kubernetes/google/main.tf
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
    required_version                        = ">= 1.0.6"
}

locals {
    prefix                                  = "${var.info.name}-${var.cluster.name}"
    cluster_ca_certificate                  = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
}

data "aws_availability_zones" "available" {}

data "aws_eks_cluster_auth" "cluster" {
    name                                    = module.eks.cluster_id
}

data "aws_eks_cluster" "cluster" {
    name                                    = module.eks.cluster_id
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  VPC
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module "vpc" {
    source  = "terraform-aws-modules/vpc/aws"

    name                                    = "${local.prefix}-vpc"
    cidr                                    = "10.0.0.0/16"
    azs                                     = data.aws_availability_zones.available.names
    private_subnets                         = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    public_subnets                          = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
    enable_nat_gateway                      = true
    single_nat_gateway                      = true
    enable_dns_hostnames                    = true

    tags = {
        "kubernetes.io/cluster/${local.prefix}" = "shared"
    }

    public_subnet_tags = {
        "kubernetes.io/cluster/${local.prefix}" = "shared"
        "kubernetes.io/role/elb"            = "1"
    }

    private_subnet_tags = {
        "kubernetes.io/cluster/${local.prefix}" = "shared"
        "kubernetes.io/role/internal-elb"   = "1"
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Security Groups
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
resource "aws_security_group" "worker_group_primary" {
    name_prefix                             = "${local.prefix}-primary"
    vpc_id                                  = module.vpc.vpc_id

    ingress {
        from_port                           = 22
        to_port                             = 22
        protocol                            = "tcp"

        cidr_blocks                         = [
            "10.0.0.0/8",
        ]
    }
}

resource "aws_security_group" "worker_group_secondary" {
    name_prefix                             = "${local.prefix}-secondary"
    vpc_id                                  = module.vpc.vpc_id

    ingress {
        from_port                           = 22
        to_port                             = 22
        protocol                            = "tcp"

        cidr_blocks                         = [
            "192.168.0.0/16",
        ]
    }
}

resource "aws_security_group" "worker_group_all" {
    name_prefix                             = "${local.prefix}-all"
    vpc_id                                  = module.vpc.vpc_id

    ingress {
        from_port                           = 22
        to_port                             = 22
        protocol                            = "tcp"

        cidr_blocks                         = [
            "10.0.0.0/8",
            "172.16.0.0/12",
            "192.168.0.0/16",
        ]
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  EKS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module "eks" {
    source                                  = "terraform-aws-modules/eks/aws"
    cluster_name                            = local.prefix
    cluster_version                         = "1.21"
    vpc_id                                  = module.vpc.vpc_id
    subnets                                 = module.vpc.private_subnets

    workers_group_defaults                  = {
        root_volume_type                    = "gp2"
    }

    worker_groups                           = [
        {
            name                            = "${local.prefix}-${var.worker_groups.primary.name}"
            instance_type                   = var.worker_groups.primary.machine_type
            asg_desired_capacity            = var.worker_groups.primary.node_count
            additional_security_group_ids   = [aws_security_group.worker_group_primary.id]
        },
        {
            name                            = "${local.prefix}-${var.worker_groups.secondary.name}"
            instance_type                   = var.worker_groups.secondary.machine_type
            asg_desired_capacity            = var.worker_groups.secondary.node_count
            additional_security_group_ids   = [aws_security_group.worker_group_secondary.id]
        },
    ]
}