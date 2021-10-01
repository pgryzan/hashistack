#!/bin/bash

###############################################################################################
#
#   Repo:           root/bootstrap
#   File Name:      docker.sh
#   Author:         Patrick Gryzan
#   Company:        Hashicorp
#   Date:           April 2021
#   Description:    This is the configuration file for the server. Assume all the packages have been
#                   installed.
#
###############################################################################################

set -e

#############################################################################################################################
#   Setup Environment
#############################################################################################################################
REGION="east"
DATA_CENTER="dc1"
RETRY_JOIN=""
NAME=""
RECURSORS='"8.8.8.8", "8.8.4.4"'

BIN="/usr/local/bin"

#   Grab Arguments
while getopts r:d:j:x:q: option
do
case "${option}"
in
r) REGION=${OPTARG};;
d) DATA_CENTER=${OPTARG};;
j) RETRY_JOIN=${OPTARG};;
x) NAME=${OPTARG};;
q) RECURSORS=${OPTARG};;
esac
done

touch ~/.bashrc

#############################################################################################################################
#   Consul
#############################################################################################################################
CONSUL_CONFIG="/etc/consul.d"
CONSUL_PACKAGE="/opt/consul"

sudo mkdir --parents ${CONSUL_CONFIG} ${CONSUL_PACKAGE}

cat <<-EOF > /etc/systemd/system/consul.service
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=${CONSUL_CONFIG}/consul.hcl

[Service]
User=consul
Group=consul
ExecStart=${BIN}/consul agent -config-dir=${CONSUL_CONFIG}/
ExecReload=${BIN}/consul reload
ExecStop=${BIN}/consul leave
KillMode=process
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

cat <<-EOF > ${CONSUL_CONFIG}/consul.hcl
datacenter = "${DATA_CENTER}"
data_dir = "${CONSUL_PACKAGE}/"
log_file = "${CONSUL_PACKAGE}/"
client_addr = "0.0.0.0"
retry_interval = "5s"
bind_addr = "{{ GetInterfaceIP \"ens4\" }}"
retry_join = [ "${RETRY_JOIN}" ]
recursors = [ ${RECURSORS} ]
connect {
    enabled = true
}
ports {
    grpc = 8502
}
EOF

sudo useradd --system --home ${CONSUL_CONFIG} --shell /bin/false consul
sudo chown --recursive consul:consul ${CONSUL_CONFIG} ${CONSUL_PACKAGE}
sudo chmod 640 ${CONSUL_CONFIG}/consul.hcl
sudo chmod -R 755 ${CONSUL_PACKAGE}

#   Enable the Service
echo "starting consul server"
sudo systemctl enable consul
sudo service consul start

#   Configure Port Forwarding
echo "configuring resolved port forwarding and iptables"
sudo mkdir --parents /etc/systemd/resolved.conf.d
cat <<-EOF > /etc/systemd/resolved.conf.d/consul.conf
[Resolve]
DNS=127.0.0.1
Domains=~consul
EOF
systemctl restart systemd-resolved

sudo iptables -t nat -A PREROUTING -p udp -m udp --dport 53 -j REDIRECT --to-ports 8600
sudo iptables -t nat -A PREROUTING -p tcp -m tcp --dport 53 -j REDIRECT --to-ports 8600
sudo iptables -t nat -A OUTPUT -d localhost -p udp -m udp --dport 53 -j REDIRECT --to-ports 8600
sudo iptables -t nat -A OUTPUT -d localhost -p tcp -m tcp --dport 53 -j REDIRECT --to-ports 8600

#############################################################################################################################
#   Nomad
#############################################################################################################################
NOMAD_CONFIG="/etc/nomad.d"
NOMAD_PACKAGE="/opt/nomad"

sudo mkdir --parents ${NOMAD_CONFIG} ${NOMAD_PACKAGE}

cat <<-EOF > /etc/systemd/system/nomad.service
[Unit]
Description=Nomad
Documentation=https://nomadproject.io/docs/
Wants=network-online.target
After=network-online.target

# When using Nomad with Consul it is not necessary to start Consul first. These
# lines start Consul before Nomad as an optimization to avoid Nomad logging
# that Consul is unavailable at startup.
Wants=consul.service
After=consul.service

[Service]
User=root
Group=root
ExecReload=/bin/kill -HUP $MAINPID
ExecStart=${BIN}/nomad agent -config ${NOMAD_CONFIG}
KillMode=process
KillSignal=SIGINT
LimitNOFILE=65536
LimitNPROC=infinity
Restart=on-failure
RestartSec=2
StartLimitBurst=3
StartLimitInterval=10
TasksMax=infinity
OOMScoreAdjust=-1000

[Install]
WantedBy=multi-user.target
EOF

cat <<-EOF > ${NOMAD_CONFIG}/nomad.hcl
name        = "${NAME}"
region      = "${REGION}"
datacenter  = "${DATA_CENTER}"
data_dir    = "${NOMAD_PACKAGE}/"
log_file    = "${NOMAD_PACKAGE}/"
bind_addr   = "0.0.0.0"

client {
    enabled = true
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
        allow_privileged = true
    }
}
EOF

#   Enable the Service
echo "starting nomad server"
sudo systemctl enable nomad
sudo service nomad start

#   Added to ensure that the Consul domain is picked up by the resolver
systemctl restart systemd-resolved

exit 0