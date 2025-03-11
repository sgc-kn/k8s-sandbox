# deploy to fresh cluster
# bootstrap: cluster config argocd-bootstrap

# setup and connect remote microk8s
microk8s host:
  just microk8s-setup {{host}}
  just microk8s-connect {{host}}

# setup remote k8s cluster (ubuntu, microk8s)
microk8s-setup host:
  ssh root@{{host}} snap install microk8s --channel=latest/edge/strict
  ssh root@{{host}} microk8s start
  ssh root@{{host}} microk8s enable cert-manager
  ssh root@{{host}} microk8s enable dns
  ssh root@{{host}} microk8s enable hostpath-storage
  ssh root@{{host}} microk8s enable ingress
  ssh root@{{host}} microk8s status --wait-ready

# setup kubectl connection for remote microk8s
microk8s-connect host:
  ssh root@{{host}} microk8s config > $KUBECONFIG
  kubectl get svc > /dev/null

# bootstrap argocd
argocd-bootstrap: argocd-install argocd-key argocd-pwd

# argocd: install
argocd-install:
  # install argocd
  kubectl create namespace argocd || true
  kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# argocd: configure deploy key
argocd-key:
  # configure access to private repo
  bash setup-deploy-key.sh
  read -p "Press Enter to continue"

# argocd: print admin password
argocd-pwd:
  # print admin's password
  argocd admin initial-password -n argocd

# deploy prod environment
deploy-prod:
  ./setup-cluster-secrets.sh prod
  kubectl apply -f appsets/prod.yaml

# deploy dev environment
deploy-dev:
  ./setup-cluster-secrets.sh dev
  kubectl apply -f appsets/dev.yaml

# forward argocd-server to http://localhost:8080
fwd-argocd:
  kubectl port-forward svc/argocd-server -n argocd 8080:80

# forward dagster-webserver to http://localhost:8081
fwd-dagster:
  kubectl port-forward svc/dagster-dagster-webserver -n dagster 8081:80
