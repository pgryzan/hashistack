 ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Repo:           hashistack
//  File Name:      tfc/kubernetes/google/outputs.tf
//  Author:         Patrick Gryzan
//  Company:        Hashicorp
//  Date:           September 2021
//  Description:    This is the outputs file
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

output "cluster" {
    sensitive                   = true
    value                       = {
        endpoint                = google_container_cluster.cluster.endpoint
        client_certificate      = base64decode(google_container_cluster.cluster.master_auth[0].client_certificate)
        client_key              = base64decode(google_container_cluster.cluster.master_auth[0].client_key)
        cluster_ca_certificate  = base64decode(google_container_cluster.cluster.master_auth[0].cluster_ca_certificate)
    }
}