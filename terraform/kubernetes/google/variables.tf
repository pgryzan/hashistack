////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Repo:           hashistack
//  File Name:      tfc/kubernetes/google/variables.tf
//  Author:         Patrick Gryzan
//  Company:        Hashicorp
//  Date:           September 2021
//  Description:    This is the input variables file for the terraform project
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Global Workspace Information
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
variable "global" {
    type            = map
    description     = "Global Workspace Information"
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  GKE Configuration
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
variable "cluster" {
    type            = map
    description     = "Cluster Information"
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Consul
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
variable "consul" {
    type            = map
    description     = "Consul Information"
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Vault
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
variable "vault" {
    type            = map
    description     = "Vault Information"
}