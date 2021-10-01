////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Repo:           hashistack
//  File Name:      tfc/global/outputs.tf
//  Author:         Patrick Gryzan
//  Company:        Hashicorp
//  Date:           September 2021
//  Description:    This is the outputs file
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

output "aws" {
    sensitive                   = true
    value                       = var.aws
}

output "azure" {
    sensitive                   = true
    value                       = var.azure
}

output "gcp" {
    sensitive                   = true
    value                       = var.gcp
}

output "consul" {
    sensitive                   = true
    value                       = var.consul
}

output "vault" {
    sensitive                   = true
    value                       = var.vault
}

output "nomad" {
    sensitive                   = true
    value                       = var.nomad
}

output "info" {
    sensitive                   = true
    value                       = var.info
}