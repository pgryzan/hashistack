////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Repo:           hashistack
//  File Name:      kubernetes/modules/terraform-helm-consul/variables.tf
//  Author:         Patrick Gryzan
//  Company:        Hashicorp
//  Date:           September 2021
//  Description:    This is the input variables file for the consul module
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Cluster Information
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
variable "cluster" {
    type            = map
    description     = "Cluster Configuration"
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Consul Configuration
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
variable "replicas" {
    description     = "The number of consul replicas"
    default         = 3
}

variable "consul_version" {
    description     = "The version of Consul enterprise"
    default         = "1.10.2"
}

variable "license" {
    type            = string
    description     = "The license for Consul enterprise"
    default         = ""
    sensitive       = true
}

variable "federation_token" {
    type            = map
    description     = "The Consul federation token"
    default         = null
    sensitive       = true
}

variable "gossip_encryption_key" {
    description     = "The Consul Gossip Encryption Key"
    default         = "pUqJrVyVRj5jsiYEkM/tFQYfWyJIv4s3XkvDwy7Cu5s="
    sensitive       = true
}