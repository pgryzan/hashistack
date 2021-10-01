#!/bin/bash

###############################################################################################
#
#   Repo:           /scripts/bash
#   File Name:      hashistack.sh
#   Author:         Patrick Gryzan
#   Company:        Hashicorp
#   Date:           April 2021
#   Description:    This is the linux installation script
#
###############################################################################################

set -e

. /etc/os-release

#############################################################################################################################
#   Environment
#############################################################################################################################
CONSUL_VERSION=""
NOMAD_VERSION=""
VAULT_VERSION=""
USERNAME=""
PASSWORD=""

BIN="/usr/local/bin"

#   Grab Arguments
while getopts c:n:v:u:p: option
do
case "${option}"
in
c) CONSUL_VERSION=${OPTARG};;
n) NOMAD_VERSION=${OPTARG};;
v) VAULT_VERSION=${OPTARG};;
u) USERNAME=${OPTARG};;
p) PASSWORD=${OPTARG};;
esac
done

case ${NAME,,} in
    'ubuntu')
        sudo sed -i 's|PasswordAuthentication no|PasswordAuthentication yes|g' /etc/ssh/sshd_config
        # sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
        sudo service ssh restart

        curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
        sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" 
        sudo apt-get -y update
        sudo apt-get install unzip curl default-jdk sshpass jq -y

        sudo useradd -s /bin/bash -d /home/${USERNAME}/ -m -G sudo ${USERNAME}
        echo -e "${PASSWORD}\n${PASSWORD}" | sudo passwd ${USERNAME}
    ;;
    'centos stream' | 'centos linux' | 'rhel')
        sudo setenforce 0
        sudo sed -i 's|^SELINUX=.*|SELINUX=permissive|g' /etc/selinux/config
        sudo sed -i 's|PasswordAuthentication no|PasswordAuthentication yes|g' /etc/ssh/sshd_config
        # sudo sed -i 's|PermitRootLogin no|PermitRootLogin yes|g' /etc/ssh/sshd_config
        sudo systemctl restart sshd.service

        sudo yum install yum-utils -y
        sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
        sudo yum -y update
        sudo yum install unzip curl java-1.8.0-openjdk jq -y

        sudo useradd -s /bin/bash -d /home/${USERNAME}/ -m ${USERNAME}
        sudo usermod -aG wheel ${USERNAME}
        echo -e "${PASSWORD}\n${PASSWORD}" | sudo passwd ${USERNAME}
    ;;
    *) echo -n "unknown operating system"; exit 1 ;;
esac

# Disable password prompts
echo "${USERNAME} ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/${USERNAME}

# Make sure the binaries can be found
export PATH=$PATH:${BIN}

#############################################################################################################################
#   Open Source
#############################################################################################################################
case ${NAME,,} in
    'ubuntu') sudo apt-get install terraform packer boundary waypoint;;
    'centos stream' | 'centos linux' | 'rhel') sudo yum -y install terraform packer boundary waypoint;;
    *) echo -n "unknown operating system"; exit 1 ;;
esac

terraform -install-autocomplete
packer -autocomplete-install
boundary -autocomplete-install
waypoint -autocomplete-install

# Install CNI plugins
echo -n "Installing CNI plugins"
curl -s -L -o /tmp/cni-plugins.tgz https://github.com/containernetworking/plugins/releases/download/v0.9.1/cni-plugins-linux-amd64-v0.9.1.tgz
mkdir -p /opt/cni/bin
tar -C /opt/cni/bin -xzf /tmp/cni-plugins.tgz

#############################################################################################################################
#   Enterpise
#############################################################################################################################
#   Consul
echo -n "Setting up consul ${CONSUL_VERSION}"
curl -fsSL -o /tmp/consul.zip "https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip"
unzip -o -d ${BIN}/ /tmp/consul.zip
consul -autocomplete-install
complete -C ${BIN}/consul consul
sudo setcap cap_ipc_lock=+ep ${BIN}/consul
sudo rm /tmp/consul.zip

#   Vault
echo -n "Setting up vault ${VAULT_VERSION}"
curl -fsSL -o /tmp/vault.zip "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip"
unzip -o -d ${BIN}/ /tmp/vault.zip
vault -autocomplete-install
complete -C ${BIN}/vault vault
sudo setcap cap_ipc_lock=+ep ${BIN}/vault
sudo rm /tmp/vault.zip

#   Nomad
echo -n "Setting up nomad ${NOMAD_VERSION}"
curl -fsSL -o /tmp/nomad.zip "https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip"
unzip -o -d ${BIN}/ /tmp/nomad.zip
nomad -autocomplete-install
complete -C ${BIN}/nomad nomad
sudo setcap cap_ipc_lock=+ep ${BIN}/nomad
sudo rm /tmp/nomad.zip

exit 0