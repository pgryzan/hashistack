////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Repo:           terraform/gcp
//  File Name:      outputs.tf
//  Author:         Patrick Gryzan
//  Company:        Hashicorp
//  Date:           September 2020
//  Description:    This is the input variables file for the terraform project
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

output "outputs" {
    value                   = {
        server              = google_compute_instance.server.network_interface.0.access_config.0.nat_ip
        windows             = google_compute_instance.client_windows.network_interface.0.access_config.0.nat_ip
        ssh_server          = "ssh -o stricthostkeychecking=no ${ var.ssh.username }@${ google_compute_instance.server.network_interface.0.access_config.0.nat_ip } -y"
        ssh_docker          = "ssh -o stricthostkeychecking=no ${ var.ssh.username }@${ google_compute_instance.client_docker.network_interface.0.access_config.0.nat_ip } -y"
        ssh_podman          = "ssh -o stricthostkeychecking=no ${ var.ssh.username }@${ google_compute_instance.client_podman.network_interface.0.access_config.0.nat_ip } -y"
        ssh_windows         = "ssh -o stricthostkeychecking=no ${ var.info.username }@${ google_compute_instance.client_windows.network_interface.0.access_config.0.nat_ip }"
        consul              = "http://${ google_compute_instance.server.network_interface.0.access_config.0.nat_ip }:8500"
        nomad               = "http://${ google_compute_instance.server.network_interface.0.access_config.0.nat_ip }:4646"
        vault               = "http://${ google_compute_instance.server.network_interface.0.access_config.0.nat_ip }:8200"
        vault_nomad_token   = data.external.vault.result.nomad_token
        vault_root_token    = data.external.vault.result.root_token
        vault_unseal_key    = data.external.vault.result.unseal_key
    }
}