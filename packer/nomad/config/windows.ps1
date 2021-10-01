###############################################################################################
#
#   Repo:           root/bootstrap
#   File Name:      windows.ps1
#   Author:         Patrick Gryzan
#   Company:        Hashicorp
#   Date:           April 2021
#   Description:    Hashistack windows client installation script
#
###############################################################################################
param (
    [string]$r = "", 
    [string]$d = "",
    [string]$j = "",
    [string]$x = "",
    [string]$q = '"8.8.8.8", "8.8.4.4"'
)

$Base_Directory = "c:/users/hashistack"

Write-Host "Setting DNS on IPv4 Ethernet Adapter"
Get-DnsClientServerAddress -InterfaceAlias "Ethernet" -AddressFamily "IPv4" | Set-DnsClientServerAddress -ServerAddresses ("127.0.0.1")

Write-Host "Starting Consul"
Add-Content -Path "${Base_Directory}/consul/consul_client.hcl" -Encoding ascii -Value @"
datacenter = "${d}"
data_dir = "c:/users/hashistack/consul/"
log_file = "c:/users/hashistack/consul/"
client_addr = "0.0.0.0"
bind_addr = "{{ GetInterfaceIP \"Ethernet\" }}"
retry_interval = "5s"
retry_join = [ "${j}" ]
recursors = [ ${q} ]
connect {
    enabled = true
}
ports {
    grpc = 8502
}
"@
sc.exe create "Consul" binPath= "c:/windows/system32/consul.exe agent -config-dir=${Base_Directory}/consul/" DisplayName= "HashiCorp Consul" start= auto
sc.exe start Consul

Write-Host "Starting Nomad"
Add-Content -Path "${Base_Directory}/nomad/config/nomad_client.hcl" -Encoding ascii -Value @"
name        = "${x}"
region      = "${r}"
datacenter  = "${d}"
data_dir    = "c:/users/hashistack/nomad/"
log_file    = "c:/users/hashistack/nomad/"
plugin_dir  = "c:/users/hashistack/nomad/plugins/"
bind_addr   = "0.0.0.0"

client {
    enabled = true
    servers = [ "${j}" ]
}

consul {
    address = "127.0.0.1:8500"
}

vault {
    enabled = true
    address = "http://active.vault.service.consul:8200"
}

plugin "docker" {
    config {
        pull_activity_timeout = "15m"
        gc {
            image = false
        }
    }
}

plugin "raw_exec" {
    config {
        enabled = true
    }
}

plugin "win_iis" {
    config {
        enabled = true
        stats_interval = "5s"
    }
}
"@
sc.exe create "Nomad" binPath= "c:/windows/system32/nomad.exe agent -config ${Base_Directory}/nomad/config" DisplayName= "HashiCorp Nomad" start= auto
sc.exe start Nomad

Write-Host "Waiting for Nomad Client to Start"
Start-Sleep -s 5

Write-Host "Setting IIS Permissions on Nomad Allocations Folder"
$acl = Get-Acl "c:/users/hashistack/nomad/alloc"
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($rule)
Set-Acl "c:/users/hashistack/nomad/alloc" $acl