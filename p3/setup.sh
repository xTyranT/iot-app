#!/bin/bash

# cleaning
sudo kubectl delete pods,services --all --all-namespaces
sudo kubectl delete "$(sudo kubectl api-resources --namespaced=true --verbs=delete -o name | tr "\n" "," | sed -e 's/,$//')" --all
sudo k3d cluster delete --all

# install docker
sudo apt update
sudo apt install ca-certificates curl -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo groupadd docker
sudo usermod -aG docker $USER

# install k3d

curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
sudo rm kubectl

# install argocd

curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo rm argocd-linux-amd64

# setup the kubernetes environment

sudo k3d cluster create iot-kouferka -p 8080:80@loadbalancer -p 8443:443@loadbalancer -p 8888:8888@loadbalancer
sudo kubectl create namespace argocd
sudo kubectl create namespace dev
mkdir ~/.kube/
sudo k3d kubeconfig get iot-kouferka > ~/.kube/config

# setup argocd

sudo kubectl create -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
sudo kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
sudo kubectl -n argocd rollout status deployment argocd-server
sudo kubectl apply -f ./argocd.yml -n argocd
PSWD=$(argocd admin initial-password -n argocd | head -n 1)
argocd login localhost:8080 --username admin --password $PSWD --insecure --grpc-web
argocd account update-password --current-password $PSWD --new-password password
kubectl config set-context --current --namespace=argocd

# createe and sync argocd with the app

argocd app create iot-app --repo https://github.com/xTyranT/iot-app.git --path 'p3/app' --dest-server https://kubernetes.default.svc --dest-namespace dev
argocd app sync iot-app --grpc-web
argocd app set iot-app --sync-policy automated --grpc-web
argocd app set iot-app --auto-prune --allow-empty --grpc-web
argocd app get iot-app --grpc-web
