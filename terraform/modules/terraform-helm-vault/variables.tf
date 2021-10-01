////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Repo:           hashistack
//  File Name:      modules/terraform-helm-vault/variables.tf
//  Author:         Patrick Gryzan
//  Company:        Hashicorp
//  Date:           August 2021
//  Description:    This is the input variables file for the vault module
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  GCP Credentials
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
variable "gcp" {
    type            = map
    description     = "The GCP Provider Information"
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Cluster Information
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
variable "cluster" {
    type            = map
    description     = "Cluster Configuration"
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  vault Configuration
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
variable "replicas" {
    description     = "The number of vault replicas"
    default         = 3
}

variable "vault_version" {
    description     = "The version of vault enterprise"
    default         = "1.10.2"
}

variable "license" {
    type            = string
    description     = "The license for vault enterprise"
    default         = ""
    sensitive       = true
}