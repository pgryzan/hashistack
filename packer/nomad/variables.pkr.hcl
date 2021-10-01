////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Repo:           packer
//  File Name:      variables.pkr.hcl
//  Author:         Patrick Gryzan
//  Company:        Hashicorp
//  Date:           April 2021
//  Description:    This is the packer file to create the automation framework images
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
variable "gcp" {
    type                = map(string)
    description         = "The GCP provider information"
}

variable "ssh" {
    type                = map(string)
    description         = "The SSH information"
}

variable "ubuntu_image" {
    type                = map(string)
    description         = "Base image information"
    default             = {
        id              = "ubuntu-2004-lts"
        disk_size       = 20
    }
}

variable "redhat_image" {
    type                = map(string)
    description         = "Base image information"
    default             = {
        id              = "centos-stream-8"
        disk_size       = 30
    }
}

variable "windows_image" {
    type                = map(string)
    description         = "Base image information"
    default             = {
        id              = "windows-2019-for-containers"
        disk_size       = 50
        winrm_username  = "packer"
    }
}

variable "stack" {
    type                = map(string)
    description         = "HashiCorp Solution Versions"
    default             = {
        consul          = "1.9.5+ent"
        name            = "framework"
        nomad           = "1.0.4+ent"
        vault           = "1.7.1+ent"
        version         = "0.1.0"
    }
}