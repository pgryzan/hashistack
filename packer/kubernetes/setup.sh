#!/bin/bash

###############################################################################################
#
#   Repo:           /scripts/bash
#   File Name:      hashistack.sh
#   Author:         Patrick Gryzan
#   Company:        Hashicorp
#   Date:           September 2021
#   Description:    This is the linux installation script
#
###############################################################################################

set -e

NAME="ubuntu"
DIR="/home/$NAME"
KUBE="$DIR/.kube"

sudo apt-get -y update
sudo snap install microk8s --classic
sudo mkdir -p $KUBE
sudo usermod -a -G microk8s $NAME
sudo chown -f -R $NAME $KUBE
sudo microk8s config > $KUBE/config

sudo microk8s enable dashboard dns registry helm3 prometheus registry ingress
sudo microk8s.kubectl config view --raw > $KUBE/config
sudo chmod 400 $KUBE/config
sudo snap install helm --classic

# sudo microk8s stop

touch $DIR/.bash_profile
echo -e "alias kubectl='sudo microk8s kubectl'" >> $DIR/.bash_profile

# token=$(sudo microk8s kubectl -n kube-system get secret | grep default-token | cut -d " " -f1)
# sudo microk8s kubectl -n kube-system describe secret $token
# sudo microk8s kubectl port-forward -n kube-system --address 0.0.0.0 service/kubernetes-dashboard 10443:443
# sudo microk8s.kubectl config view --raw -o json
# sudo microk8s.kubectl config view --raw -o jsonpath='{.users[].user.token}'
# sudo microk8s.kubectl config view --raw -o jsonpath='{.clusters[].cluster.certificate-authority-data}'