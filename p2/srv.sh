#!/bin/bash

sudo apt update && sudo apt install curl -y
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -s - \
    --write-kubeconfig-mode 644 --advertise-address=192.168.56.110\
    --node-ip=192.168.56.110

sleep 20

sudo mkdir -p /run/systemd/resolve/
echo -e "nameserver 8.8.8.8\\nnameserver 8.8.4.4" | sudo tee -a /run/systemd/resolve/stub-resolv.conf
sudo ln -rsf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
sudo sed -i "s/127.0.0.1/192.168.56.110/" /etc/rancher/k3s/k3s.yaml

kubectl apply -n kube-system -f /vagrant/app1.yml --validate=false
kubectl apply -n kube-system -f /vagrant/app2.yml --validate=false
kubectl apply -n kube-system -f /vagrant/app3.yml --validate=false
kubectl apply -n kube-system -f /vagrant/ingress.yml --validate=false