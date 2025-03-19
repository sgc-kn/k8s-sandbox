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
argocd-bootstrap: argocd-install argocd-key

# argocd: install
argocd-install:
  # install argocd
  kubectl create namespace argocd || true
  kubectl apply -n argocd -k apps/argocd/envs/dev
  # no matter the env; this will be overruled by just deploy-* later

# argocd: configure deploy key
argocd-key:
  # configure access to private repo
  bash setup-deploy-key.sh
  read -p "Press Enter to continue"

# deploy prod environment
deploy-prod:
  kubectl config rename-context $(kubectl config current-context) prod || true
  ./setup-cluster-secrets.sh prod
  kubectl apply -f appsets/prod.yaml

# deploy dev environment
deploy-dev:
  kubectl config rename-context $(kubectl config current-context) dev || true
  ./setup-cluster-secrets.sh dev
  kubectl apply -f appsets/dev.yaml

fwd-dev-argocd:
  kubectl --context dev port-forward svc/argocd-server -n argocd 8080:80

fwd-prod-argocd:
  kubectl --context prod port-forward svc/argocd-server -n argocd 8000:80

fwd-dev-dagster:
  kubectl --context dev port-forward svc/dagster-dagster-webserver -n dagster 8081:80

fwd-prod-dagster:
  kubectl --context prod port-forward svc/dagster-dagster-webserver -n dagster 8001:80
