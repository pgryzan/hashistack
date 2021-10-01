#!/bin/bash

###############################################################################################
#
#   Repo:           root/bootstrap
#   File Name:      server.sh
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
CONSUL_LICENSE=""
NOMAD_LICENSE=""
VAULT_LICENSE=""
NAME=""
RECURSORS='"8.8.8.8", "8.8.4.4"'

BIN="/usr/local/bin"

#   Grab Arguments
while getopts r:d:c:n:v:x:q: option
do
case "${option}"
in
r) REGION=${OPTARG};;
d) DATA_CENTER=${OPTARG};;
c) CONSUL_LICENSE=${OPTARG};;
n) NOMAD_LICENSE=${OPTARG};;
v) VAULT_LICENSE=${OPTARG};;
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
Type=exec
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
ui = true
server = true
bootstrap_expect = 1
client_addr = "0.0.0.0"
retry_interval = "5s"
bind_addr = "{{ GetInterfaceIP \"ens4\" }}"
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

#   Set License
if [[ $CONSUL_LICENSE != "" ]] ; then
    echo 'waiting for consul to startup'
    sleep 10
    consul license put "${CONSUL_LICENSE}"
fi

#############################################################################################################################
#   Vault
#############################################################################################################################
VAULT_CONFIG="/etc/vault.d"
VAULT_PACKAGE="/opt/vault"

sudo mkdir --parents ${VAULT_CONFIG} ${VAULT_PACKAGE}

# Write the Service Configuration
cat <<-EOF > /etc/systemd/system/vault.service
[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=${VAULT_CONFIG}/vault.hcl
StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
User=vault
Group=vault
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
Capabilities=CAP_IPC_LOCK+ep
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=${BIN}/vault server -config=${VAULT_CONFIG}/vault.hcl
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
StartLimitInterval=60
StartLimitIntervalSec=60
StartLimitBurst=3
LimitNOFILE=65536
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target
EOF

# Write vault.hcl configuration
cat <<-EOF > ${VAULT_CONFIG}/vault.hcl
storage "consul" {
    address = "127.0.0.1:8500"
    path    = "vault/"
}

listener "tcp" {
    address = "0.0.0.0:8200"
    tls_disable = true
}

disable_mlock = true
ui=true
EOF

sudo useradd --system --home ${VAULT_CONFIG} --shell /bin/false vault
sudo chown --recursive vault:vault ${VAULT_CONFIG} ${VAULT_PACKAGE}
sudo chmod 640 ${VAULT_CONFIG}/vault.hcl
sudo chmod -R 755 ${VAULT_PACKAGE}

echo "starting vault server"
sudo systemctl enable vault
sudo service vault start

# Sleep 30 seconds
echo 'waiting for vault to startup'
sleep 30

# Export VAULT_ADDR to the bash environment
export VAULT_ADDR=http://127.0.0.1:8200/
echo -e "export VAULT_ADDR=http://127.0.0.1:8200/" >> ~/.bashrc

# Initialize Vault server
sudo mkdir --parents ${VAULT_PACKAGE}
sudo chmod -R 755 ${VAULT_PACKAGE}
vault operator init -key-shares=1 -key-threshold=1 > ${VAULT_PACKAGE}/init.log

# Extract root token and unseal key from init.log
token=$(sed -n 3p ${VAULT_PACKAGE}/init.log | cut -d':' -f2 | cut -d' ' -f2)
unseal_key=$(sed -n 1p ${VAULT_PACKAGE}/init.log | cut -d':' -f2 | cut -d' ' -f2)

# Write root token to /root/token
echo $token > ${VAULT_PACKAGE}/root_token

# Write unseal key to /root/unseal_key
echo $unseal_key > ${VAULT_PACKAGE}/unseal_key

# Export VAULT_TOKEN to the bash environment
export VAULT_TOKEN=$token
echo -e "export VAULT_TOKEN=$token" >> ~/.bashrc

# Unseal Vault server
vault operator unseal $unseal_key

# Setup Nomad Integration
echo "setting up nomad integration"
cat <<-EOF > ${VAULT_PACKAGE}/nomad-policy.hcl
# Allow creating tokens under "nomad-cluster" token role. The token role name should be updated if "nomad-cluster" is not used.
path "auth/token/create/nomad-cluster" {
  capabilities = ["update"]
}
# Allow looking up "nomad-cluster" token role. The token role name should be updated if "nomad-cluster" is not used.
path "auth/token/roles/nomad-cluster" {
  capabilities = ["read"]
}
# Allow looking up the token passed to Nomad to validate # the token has the proper capabilities. This is provided by the "default" policy.
path "auth/token/lookup-self" {
  capabilities = ["read"]
}
# Allow looking up incoming tokens to validate they have permissions to access the tokens they are requesting. This is only required if is set to false.
path "auth/token/lookup" {
  capabilities = ["update"]
}
# Allow revoking tokens that should no longer exist. This allows revoking tokens for dead tasks.
path "auth/token/revoke-accessor" {
  capabilities = ["update"]
}
# Allow checking the capabilities of our own token. This is used to validate the token upon startup.
path "sys/capabilities-self" {
  capabilities = ["update"]
}
# Allow our own token to be renewed.
path "auth/token/renew-self" {
  capabilities = ["update"]
}
EOF

cat <<-EOF > ${VAULT_PACKAGE}/nomad-cluster-role.json
{
    "token_explicit_max_ttl": 0,
    "name": "nomad-cluster",
    "orphan": true,
    "token_period": 259200,
    "renewable": true
}
EOF

#   Generate the Nomad Token
vault policy write nomad-server ${VAULT_PACKAGE}/nomad-policy.hcl
vault token create -policy nomad-server -period 72h -orphan > ${VAULT_PACKAGE}/nomad-policy.log
nomad_token=$(sed -n 3p ${VAULT_PACKAGE}/nomad-policy.log | cut -d' ' -f17)
echo $nomad_token > ${VAULT_PACKAGE}/nomad_token
#   Create the nomad-cluster role
vault write /auth/token/roles/nomad-cluster @${VAULT_PACKAGE}/nomad-cluster-role.json

if [[ $VAULT_LICENSE != "" ]] ; then
    echo "writing vault license"
    vault write /sys/license text="${VAULT_LICENSE}"
fi

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

server {
    enabled = true
    bootstrap_expect = 1
}

consul {
    address = "127.0.0.1:8500"
}

vault {
    enabled = true
    address = "http://127.0.0.1:8200"
    token = "$(cat ${VAULT_PACKAGE}/nomad_token)"
    task_token_ttl = "1h"
    create_from_role = "nomad-cluster"
}
EOF

#   Enable the Service
echo "starting nomad server"
sudo systemctl enable nomad
sudo service nomad start

if [[ $NOMAD_LICENSE != "" ]]  ; then
echo 'waiting for nomad to startup'
cat <<-EOF >> ${NOMAD_CONFIG}/nomad.hclic
${NOMAD_LICENSE}
EOF
    sleep 10
    nomad license put "${NOMAD_CONFIG}/nomad.hclic"
    sudo rm "${NOMAD_CONFIG}/nomad.hclic"
fi

#   Added to ensure that the Consul domain is picked up by the resolver
systemctl restart systemd-resolved

exit 0