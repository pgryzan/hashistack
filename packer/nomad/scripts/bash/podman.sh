#!/bin/bash

###############################################################################################
#
#   Repo:           /scripts/bash
#   File Name:      podman.sh
#   Author:         Patrick Gryzan
#   Company:        Hashicorp
#   Date:           April 2021
#   Description:    Podman setup script for linux machines
#
###############################################################################################

set -e

. /etc/os-release

case ${NAME,,} in
    'ubuntu')
        echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
        curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/Release.key | sudo apt-key add -
        sudo apt-get update
        sudo apt-get -y install podman git wget
    ;;
    'centos stream')
        sudo dnf -y module disable container-tools
        sudo dnf -y install 'dnf-command(copr)'
        sudo dnf -y copr enable rhcontainerbot/container-selinux
        sudo curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/CentOS_8_Stream/devel:kubic:libcontainers:stable.repo
        sudo dnf -y --refresh install gcc podman
        sudo yum -y install git wget jq
    ;;
    'centos linux' | 'rhel')
        sudo yum -y install podman git wget
    ;;
    *) echo -n "unknown operating system"; exit 1 ;;
esac

NOMAD_CONFIG="/etc/nomad.d"
NOMAD_PACKAGE="/opt/nomad"
NOMAD_PLUGINS="${NOMAD_PACKAGE}/plugins"

sudo mkdir --parents ${NOMAD_CONFIG} ${NOMAD_PACKAGE} ${NOMAD_PLUGINS}

#   Download Go
echo 'installing go'
cd /tmp
wget https://golang.org/dl/go1.16.3.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.16.3.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

#   Build nomad-driver-podman
echo 'build nomad-driver-podman'
git clone https://github.com/hashicorp/nomad-driver-podman.git
cd nomad-driver-podman
./build.sh
sudo mv nomad-driver-podman ${NOMAD_PLUGINS}/

exit 0

#   Test - sudo curl -s --unix-socket /run/podman/podman.sock http://d/v1.0.0/libpod/info