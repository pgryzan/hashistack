#!/bin/bash

###############################################################################################
#
#   Repo:           /scripts/bash
#   File Name:      envoy.sh
#   Author:         Patrick Gryzan
#   Company:        Hashicorp
#   Date:           April 2021
#   Description:    Envoy proxy setup script for linux machines
#
###############################################################################################

set -e

#   Get the OS Info
. /etc/os-release

#   Install Envoy
case ${NAME,,} in
    'ubuntu') 
        curl -sL 'https://getenvoy.io/gpg' | sudo apt-key add -
        sudo add-apt-repository \
            "deb [arch=amd64] https://dl.bintray.com/tetrate/getenvoy-deb \
            $(lsb_release -cs) \
            stable"
        sudo apt-get update && sudo apt-get install -y getenvoy-envoy
        envoy --version
    ;;
    'centos stream' | 'centos linux' | 'rhel')
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://getenvoy.io/linux/centos/tetrate-getenvoy.repo
        sudo yum install -y getenvoy-envoy
        envoy --version
    ;;
    *) echo -n "unknown operating system"; exit 1 ;;
esac

exit 0