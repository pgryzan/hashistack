////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Repo:           terraform/gcp
//  File Name:      main.tf
//  Author:         Patrick Gryzan
//  Company:        Hashicorp
//  Date:           April 2021
//  Description:    This is the main execution file
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Environment
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
terraform {
    required_version        = ">= 1.0.6"

    // backend "remote" {
    //     organization            = "pgryzan"
    //     workspaces {
    //         name                = "hashistack-on-premise"
    //     }
    // }
}

provider "google" {
    credentials             = var.gcp.credentials
    project                 = var.gcp.project
    region                  = var.gcp.region
    zone                    = var.gcp.zone
}

locals {
    ttl                     = 8
    tags                    = [
        "contact", var.info.contact,
        "group", var.info.group,
        "project", var.info.name,
        "expires", timeadd(timestamp(), format("%vh", var.info.ttl))
    ]
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Data
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
data "external" "vault" {
    program                 = ["bash", "${path.module}/../templates/vault.sh"]
    query                   = {
        password            = var.info.password
        username            = var.info.username
        public_ip           = google_compute_instance.server.network_interface.0.access_config.0.nat_ip
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Security Group
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
resource "google_compute_firewall" "default" {
    name                    = "${var.info.name}-firewall"
    network                 = "default"

    allow {
        protocol            = "tcp"
        ports               = [ "22", "80", "443", "1433", "4646", "4647", "4648", "5985", "5986", "8080", "8200", "8300", "8301", "8302", "8500", "8502", "9080", "9090", "9093", "9998", "9999" ]
    }

    allow {
        protocol            = "udp"
        ports               = [ "4647", "8300", "8301", "8502" ]
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Virtual Machines
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
resource "google_compute_instance" "server" {
    name                    = var.server.name
    machine_type            = var.server.type

    boot_disk {
        initialize_params {
            image           = var.image.server
            size            = var.server.volume_size
            type            = "pd-ssd"
        }
    }

    network_interface {
        network             = "default"
        access_config {
            //  An empty block creates a public ip
        }
    }

    //  Removing vm fingerprint because gpc reuses IPs. This can cause a "man in the middle" error when ssh connects.
    // provisioner "local-exec" {
    //     command             = "ssh-keygen -R ${google_compute_instance.server.network_interface.0.access_config.0.nat_ip}"
    // }

    connection {
        type                = "ssh"
        host                = google_compute_instance.server.network_interface.0.access_config.0.nat_ip
        user                = var.ssh.username 
        private_key         = var.ssh.private_key
    }

    provisioner "remote-exec" {
        inline              = [
            "sudo chmod +x /home/hashistack/config.sh",
            "sudo /home/hashistack/config.sh -r '${var.info.region}' -d '${var.info.datacenter}' -c '${var.info.consul_license}' -v '${var.info.vault_license}' -n '${var.info.nomad_license}' -x 'server'",
            "sudo rm -r /home/hashistack/config.sh"
        ]
    }
}

resource "google_compute_instance" "client_docker" {
    name                    = var.docker.name
    machine_type            = var.docker.type

    boot_disk {
        initialize_params {
            image           = var.image.docker
            size            = var.docker.volume_size
            type            = "pd-ssd"
        }
    }

    network_interface {
        network             = "default"
        access_config {
            //  An empty block creates a public ip
        }
    }

    //  Removing vm fingerprint because gpc reuses IPs. This can cause a "man in the middle" error when ssh connects.
    // provisioner "local-exec" {
    //     command             = "ssh-keygen -R ${google_compute_instance.client_docker.network_interface.0.access_config.0.nat_ip}"
    // }

    connection {
        type                = "ssh"
        host                = google_compute_instance.client_docker.network_interface.0.access_config.0.nat_ip
        user                = var.ssh.username 
        private_key         = var.ssh.private_key
    }

    provisioner "remote-exec" {
        inline              = [
            "sudo chmod +x /home/hashistack/config.sh",
            "sudo /home/hashistack/config.sh -r '${var.info.region}' -d '${var.info.datacenter}' -j '${google_compute_instance.server.network_interface.0.network_ip}' -x 'docker'",
            "sudo rm -r /home/hashistack/config.sh"
        ]
    }

    depends_on              = [ google_compute_instance.server ]
}

resource "google_compute_instance" "client_podman" {
    name                    = var.podman.name
    machine_type            = var.podman.type

    boot_disk {
        initialize_params {
            image           = var.image.podman
            size            = var.podman.volume_size
            type            = "pd-ssd"
        }
    }

    network_interface {
        network             = "default"
        access_config {
            //  An empty block creates a public ip
        }
    }

    //  Removing vm fingerprint because gpc reuses IPs. This can cause a "man in the middle" error when ssh connects.
    // provisioner "local-exec" {
    //     command             = "ssh-keygen -R ${google_compute_instance.client_podman.network_interface.0.access_config.0.nat_ip}"
    // }

    connection {
        type                = "ssh"
        host                = google_compute_instance.client_podman.network_interface.0.access_config.0.nat_ip
        user                = var.ssh.username 
        private_key         = var.ssh.private_key
    }

    provisioner "remote-exec" {
        inline              = [
            "sudo chmod +x /home/hashistack/config.sh",
            "sudo /home/hashistack/config.sh -r '${var.info.region}' -d '${var.info.datacenter}' -j '${google_compute_instance.server.network_interface.0.network_ip}' -x 'podman'",
            "sudo rm -r /home/hashistack/config.sh"
        ]
    }

    depends_on              = [ google_compute_instance.server ]
}

resource "google_compute_instance" "client_windows" {
    name                    = var.windows.name
    machine_type            = var.windows.type

    boot_disk {
        initialize_params {
            image           = var.image.windows
            size            = var.windows.volume_size
            type            = "pd-ssd"
        }
    }

    network_interface {
        network             = "default"
        access_config {
            //  An empty block creates a public ip
        }
    }

    //  Removing vm fingerprint because gpc reuses IPs. This can cause a "man in the middle" error when ssh connects.
    // provisioner "local-exec" {
    //     command             = "ssh-keygen -R ${google_compute_instance.client_windows.network_interface.0.access_config.0.nat_ip}"
    // }

    connection {
        type                = "winrm"
        host                = google_compute_instance.client_windows.network_interface.0.access_config.0.nat_ip
        user                = var.info.username 
        password            = var.info.password
        https               = true
        insecure            = true
    }

    provisioner "remote-exec" {
        inline              = [
            "powershell.exe -ExecutionPolicy Bypass -File c:/users/hashistack/config.ps1 -r \"${var.info.region}\" -d \"${var.info.datacenter}\" -j \"${google_compute_instance.server.network_interface.0.network_ip}\" -x \"windows\"",
            "powershell.exe -ExecutionPolicy Bypass \"rm c:/users/hashistack/config.ps1\""
        ]
    }

    depends_on              = [ google_compute_instance.server ]
}