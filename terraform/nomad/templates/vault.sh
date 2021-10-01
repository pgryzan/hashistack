#!/bin/bash

set -e

eval "$(jq -r '@sh "PASSWORD=\(.password) USERNAME=\(.username) PUBLIC_IP=\(.public_ip)"')"
command="log_user 0; set prompt \"\\$\"; spawn ssh -o stricthostkeychecking=no $USERNAME@$PUBLIC_IP \"cat /opt/vault/root_token && cat /opt/vault/unseal_key && cat /opt/vault/nomad_token\"; expect \"password:\"; send \"$PASSWORD\r\"; expect -re prompt; send_user \"\$expect_out(buffer)\"; exit 0;"
command=${command//'!'/'\!'}
info=$(expect -c "$command")
root_token=$(echo ${info} | cut -d ' ' -f2 | tr -d '\r')
unseal_key=$(echo ${info} | cut -d ' ' -f3 | tr -d '\r')
nomad_token=$(echo ${info} | cut -d ' ' -f4 | tr -d '\r')
jq -n --arg root_token "$root_token" --arg unseal_key "$unseal_key" --arg nomad_token "$nomad_token" '{"root_token":$root_token,"unseal_key":$unseal_key,"nomad_token":$nomad_token}'

exit 0