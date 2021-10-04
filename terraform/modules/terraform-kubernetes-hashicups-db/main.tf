////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Repo:           hashistack-kubernetes
//  File Name:      modules/hashicups/main.tf
//  Author:         Patrick Gryzan
//  Company:        Hashicorp
//  Date:           September 2021
//  Description:    This is the main execution file for consul module
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Environment
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
terraform {
    required_version    = ">= 1.0.6"
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Kubernetes
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
resource "kubernetes_namespace" "hashicups" {
    metadata {
        name            = "hashicups"
    }
}