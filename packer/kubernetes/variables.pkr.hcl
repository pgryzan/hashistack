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

variable "azure" {
    type                = map(string)
    description         = "The Azure provider information"
}