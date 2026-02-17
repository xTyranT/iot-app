#!/bin/bash
 
# cleaning
# sudo kubectl delete pods,services --all --all-namespaces
# sudo kubectl delete "$(sudo kubectl api-resources --namespaced=true --verbs=delete -o name | tr "\n" "," | sed -e 's/,$//')" --all
# sudo k3d cluster delete --all

# # install docker
# sudo apt update
# sudo apt install ca-certificates curl -y
# sudo install -m 0755 -d /etc/apt/keyrings
# sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
# sudo chmod a+r /etc/apt/keyrings/docker.asc
# sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
# Types: deb
# URIs: https://download.docker.com/linux/debian
# Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
# Components: stable
# Signed-By: /etc/apt/keyrings/docker.asc
# EOF
# sudo apt update
# sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
# sudo groupadd docker
# sudo usermod -aG docker $USER

# # install k3d

# curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
# curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
# sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
# sudo rm kubectl

# # install argocd

# curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
# sudo rm argocd-linux-amd64

# sudo k3d cluster create iot-kouferka -p 8080:80@loadbalancer -p 8443:443@loadbalancer -p 8888:8888@loadbalancer
# sudo kubectl create namespace argocd
# sudo kubectl create namespace dev
# sudo kubectl create namespace gitlab
# mkdir ~/.kube/
# sudo k3d kubeconfig get iot-kouferka > ~/.kube/config

# # setup argocd

# sudo kubectl create -n gitlab -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
# sudo kubectl patch svc argocd-server -n gitlab -p '{"spec": {"type": "LoadBalancer"}}'
# sudo kubectl -n gitlab rollout status deployment argocd-server
# sudo kubectl apply -f ./argocd.yml -n gitlab
# PSWD=$(argocd admin initial-password -n gitlab | head -n 1)
# argocd login localhost:8080 --username admin --password $PSWD --insecure --grpc-web
# argocd account update-password --current-password $PSWD --new-password password
# kubectl config set-context --current --namespace=argocd
# sudo argocd app create iot-app --repo http://localhost/root/iot.git --path 'app' --dest-server https://kubernetes.default.svc --dest-namespace dev
# sudo argocd app sync iot-app --grpc-web
# sudo argocd app set iot-app --sync-policy automated --grpc-web
# sudo argocd app set iot-app --auto-prune --allow-empty --grpc-web
# sudo argocd app get iot-app --grpc-web

sudo kubectl create namespace gitlab

# install helm

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
sudo apt install git -y


sudo helm repo add gitlab https://charts.gitlab.io/
sudo helm repo update 
sudo helm upgrade --install gitlab gitlab/gitlab \
    --namespace "gitlab" \
    --values https://gitlab.com/gitlab-org/charts/gitlab/raw/master/examples/values-minikube-minimum.yaml \
    --set global.hosts.domain="localhost" \
    --set global.hosts.externalIP=0.0.0.0 \
    --set global.hosts.https=false \
    --set certmanager.install=false \
    --set global.ingress.configureCertmanager=false \
    --timeout 600s \
    --wait

sudo kubectl wait --for=condition=Ready --timeout=1200s pod -l app=webservice -n gitlab

sudo kubectl port-forward svc/gitlab-webservice-default -n gitlab 80:8181 2>&1 >/dev/null &

sudo kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath="{.data.password}" | base64 --decode; echo


