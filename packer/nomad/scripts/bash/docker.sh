#!/bin/bash

###############################################################################################
#
#   Repo:           /scripts/bash
#   File Name:      docker.sh
#   Author:         Patrick Gryzan
#   Company:        Hashicorp
#   Date:           April 2021
#   Description:    Docker setup script for linux machines
#
###############################################################################################

set -e

#   Get the OS Info
. /etc/os-release

#   Install Docker
case ${NAME,,} in
    'ubuntu')
        sudo apt-get -y install \
            apt-transport-https \
            ca-certificates \
            curl \
            gnupg-agent \
            software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository \
            "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
            $(lsb_release -cs) \
            stable"
        sudo apt-get update && sudo apt-get -y install docker-ce docker-ce-cli containerd.io
    ;;
    'centos stream' | 'centos linux' | 'rhel')
        sudo yum install -y yum-utils
        sudo yum-config-manager \
            --add-repo \
            https://download.docker.com/linux/centos/docker-ce.repo
        sudo yum install docker-ce docker-ce-cli containerd.io
        sudo systemctl start docker
    ;;
    *) echo -n "unknown operating system"; exit 1 ;;
esac

exit 0