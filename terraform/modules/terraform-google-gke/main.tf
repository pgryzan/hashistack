////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Repo:           hashistack
//  File Name:      tfc/kubernetes/google/main.tf
//  Author:         Patrick Gryzan
//  Company:        Hashicorp
//  Date:           September 2021
//  Description:    This is the main execution file
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Environment
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
terraform {
    required_version            = ">= 1.0.6"
}

locals {
    prefix                      = "${var.info.name}-${var.cluster.name}"
    cluster_ca_certificate      = base64decode(google_container_cluster.cluster.master_auth[0].cluster_ca_certificate)
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  VPC
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
resource "google_compute_network" "vpc" {
    name                        = "${local.prefix}-vpc"
    auto_create_subnetworks     = false
}

resource "google_compute_subnetwork" "subnet" {
    name                        = "${local.prefix}-subnet"
    region                      = var.cluster.region
    network                     = google_compute_network.vpc.id
    ip_cidr_range               = "10.10.0.0/24"
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  GKE
//  It is recommended to seperate the node pool, but this is just for 
//  demonstration so go with default for startup speed
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
resource "google_container_cluster" "cluster" {
    name                        = "${local.prefix}"
    location                    = var.cluster.zone
    network                     = google_compute_network.vpc.id
    subnetwork                  = google_compute_subnetwork.subnet.id
    initial_node_count          = var.cluster.node_count

    node_config {
        machine_type            = var.cluster.machine_type
        disk_type               = "pd-ssd"

        metadata                = {
            disable-legacy-endpoints = "true"
        }

        oauth_scopes            = [
            "https://www.googleapis.com/auth/logging.write",
            "https://www.googleapis.com/auth/monitoring",
            "https://www.googleapis.com/auth/compute",
            "https://www.googleapis.com/auth/devstorage.read_write",
            "https://www.googleapis.com/auth/cloud-platform"
        ]
    }
}