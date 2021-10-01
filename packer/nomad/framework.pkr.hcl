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
//  Local Variables
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
locals {
    version             = replace(replace(var.stack.version, ".", "-"), "+", "-")
    consul              = replace(replace(var.stack.consul, ".", "-"), "+", "-")
    nomad               = replace(replace(var.stack.nomad, ".", "-"), "+", "-")
    vault               = replace(replace(var.stack.vault, ".", "-"), "+", "-")
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Builder Definitions
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
source "googlecompute" "server" {
    project_id          = var.gcp.id
    zone                = var.gcp.zone
    source_image_family = var.ubuntu_image.id
    disk_size           = var.ubuntu_image.disk_size
    ssh_username        = var.ssh.build_username
    machine_type        = "n1-standard-4"
    image_name          = "${var.stack.name}-server-${local.version}"
    image_labels        = {
        consul          = local.consul
        nomad           = local.nomad
        vault           = local.vault
    }
}

source "googlecompute" "docker" {
    project_id          = var.gcp.id
    zone                = var.gcp.zone
    source_image_family = var.ubuntu_image.id
    disk_size           = var.ubuntu_image.disk_size
    ssh_username        = var.ssh.build_username
    machine_type        = "n1-standard-4"
    image_name          = "${var.stack.name}-docker-${local.version}"
    image_labels        = {
        consul          = local.consul
        nomad           = local.nomad
        vault           = local.vault
    }
}

source "googlecompute" "podman" {
    project_id          = var.gcp.id
    zone                = var.gcp.zone
    source_image_family = var.redhat_image.id
    disk_size           = var.redhat_image.disk_size
    ssh_username        = var.ssh.build_username
    machine_type        = "n1-standard-4"
    image_name          = "${var.stack.name}-podman-${local.version}"
    image_labels        = {
        consul          = local.consul
        nomad           = local.nomad
        vault           = local.vault
    }
}

source "googlecompute" "windows" {
    project_id          = var.gcp.id
    zone                = var.gcp.zone
    source_image_family = var.windows_image.id
    disk_size           = var.windows_image.disk_size
    machine_type        = "n1-standard-8"
    image_name          = "${var.stack.name}-windows-${local.version}"
    communicator        = "winrm"
    winrm_username      = var.ssh.username
    winrm_password      = var.ssh.password
    winrm_insecure      = true
    winrm_use_ssl       = true
    metadata            = {
        windows-startup-script-cmd = "winrm quickconfig -quiet & net user /add ${var.ssh.username} ${var.ssh.password} & net localgroup administrators ${var.ssh.username} /add & winrm set winrm/config/service/auth @{Basic=\"true\"} & powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \"Set-ExecutionPolicy -ExecutionPolicy Bypass -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072\""
    }
    image_labels        = {
        consul          = local.consul
        nomad           = local.nomad
        vault           = local.vault
    }
    tags                = [ var.ssh.build_username ]
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Builders
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

build {
    name                = "server"

    sources             = [
        "sources.googlecompute.server"
    ]

    provisioner "file" {
        source          = "scripts/bash/"
        destination     = "/tmp/"
    }

    provisioner "file" {
        source          = "config/server.sh"
        destination     = "/tmp/config.sh"
    }

    provisioner "shell" {
        inline          = [
            "sudo chmod +x /tmp/hashistack.sh",
            "sudo /tmp/hashistack.sh -c '${var.stack.consul}' -n '${var.stack.nomad}' -v '${var.stack.vault}' -u '${var.ssh.username}' -p '${var.ssh.password}'",
            "sudo mv /tmp/config.sh /home/hashistack/",
            "sudo rm -r /tmp/*.sh"
        ]
    }
}

build {
    name                = "docker"

    sources             = [
        "sources.googlecompute.docker"
    ]

    provisioner "file" {
        source          = "scripts/bash/"
        destination     = "/tmp/"
    }

    provisioner "file" {
        source          = "config/docker.sh"
        destination     = "/tmp/config.sh"
    }

    provisioner "shell" {
        inline          = [
            "sudo chmod +x /tmp/hashistack.sh",
            "sudo /tmp/hashistack.sh -c '${var.stack.consul}' -n '${var.stack.nomad}' -v '${var.stack.vault}' -u '${var.ssh.username}' -p '${var.ssh.password}'",
            "sudo chmod +x /tmp/docker.sh",
            "sudo /tmp/docker.sh",
            "sudo mv /tmp/config.sh /home/hashistack/",
            "sudo rm -r /tmp/*.sh"
        ]
    }
}

build {
    name                = "podman"

    sources             = [
        "sources.googlecompute.podman"
    ]

    provisioner "file" {
        source          = "scripts/bash/"
        destination     = "/tmp/"
    }

    provisioner "file" {
        source          = "config/podman.sh"
        destination     = "/tmp/config.sh"
    }

    provisioner "shell" {
        inline          = [
            "sudo chmod +x /tmp/hashistack.sh",
            "sudo /tmp/hashistack.sh -c '${var.stack.consul}' -n '${var.stack.nomad}' -v '${var.stack.vault}' -u '${var.ssh.username}' -p '${var.ssh.password}'",
            "sudo chmod +x /tmp/podman.sh",
            "sudo /tmp/podman.sh",
            "sudo mv /tmp/config.sh /home/hashistack/",
            "sudo rm -r /tmp/*.sh"
        ]
    }
}

build {
    name                = "windows"

    sources             = [
        "sources.googlecompute.windows"
    ]

    provisioner "file" {
        source          = "scripts/powershell/"
        destination     = "C:/Temp/"
    }

    provisioner "powershell" {
        elevated_user   = var.ssh.username
        elevated_password = var.ssh.password
        inline          = [
            "c:/temp/hashistack.ps1 -c '${var.stack.consul}' -n '${var.stack.nomad}' -i 'pgryzan/product-db:20210506'",
            "Remove-Item c:/temp/*.ps1"
        ]
    }

    provisioner "file" {
        source          = "config/windows.ps1"
        destination     = "c:/users/hashistack/config.ps1"
    }
}