#!/bin/bash

sudo apt-get update && sudo apt-get install curl -y
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent" sh -s - \
    --server https://192.168.56.110:6443 --token=mytoken --node-ip=192.168.56.111