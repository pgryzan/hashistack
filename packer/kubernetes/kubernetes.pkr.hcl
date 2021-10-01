////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Repo:           packer
//  File Name:      framework.pkr.hcl
//  Author:         Patrick Gryzan
//  Company:        Hashicorp
//  Date:           April 2021
//  Description:    This is the packer file to create the automation framework server and client images
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Evironment
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
packer {
    required_plugins {
        amazon                  = {
            version             = ">= 1.0.1"
            source              = "github.com/hashicorp/amazon"
        }
        googlecompute           = {
            version             = ">= 1.0.5"
            source              = "github.com/hashicorp/googlecompute"
        }
        azure                   = {
            version             = ">= 1.0.3"
            source              = "github.com/hashicorp/azure"
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Builders
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
source "amazon-ebs" "kubernetes" {
    ami_name                    = "demo-kubernetes-ubuntu"
    instance_type               = "t2.xlarge"
    region                      = "us-east-2"
    ssh_username                = "ubuntu"
    source_ami_filter {
        filters                 = {
            name                = "ubuntu/images/*ubuntu-focal-20.04-amd64-server-*"
            root-device-type    = "ebs"
            virtualization-type = "hvm"
        }
        most_recent             = true
        owners                  = ["099720109477"]
    }
    tags                        = {
        Name                    = "demo-kubernetes"
    }
}

source "googlecompute" "kubernetes" {
    project_id                  = var.gcp.project
    zone                        = var.gcp.zone
    source_image_family         = "ubuntu-2004-lts"
    ssh_username                = "ubuntu"
    machine_type                = "n2-standard-4"
    image_name                  = "demo-kubernetes"
}

source "azure-arm" "kubernetes" {
    client_id                   = var.azure.client_id
    client_secret               = var.azure.client_secret
    tenant_id                   = var.azure.tenant_id
    subscription_id             = var.azure.subscription_id

    resource_group_name         = "pgryzan-demo"
    storage_account             = "pgryzan"
    capture_container_name      = "demo-kubernetes"
    capture_name_prefix         = "packer"

    os_type                     = "Linux"
    image_publisher             = "Canonical"
    image_offer                 = "UbuntuServer"
    image_sku                   = "20.04-LTS"
    location                    = "East US"
    vm_size                     = "Standard_DS3_v2"
}

build {
    name                        = "demo-kubernetes"
    sources                     = [ "source.amazon-ebs.kubernetes", "source.googlecompute.kubernetes", "source.azure-arm.kubernetes" ]

    provisioner "file" {
        source                  = "setup.sh"
        destination             = "/tmp/setup.sh"
    }

    provisioner "shell" {
        inline                  = [
            "sudo chmod +x /tmp/setup.sh",
            "sudo /tmp/setup.sh",
            "sudo rm -r /tmp/*.sh"
        ]
    }

    post-processor "vagrant" {}
}