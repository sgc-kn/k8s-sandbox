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

# create local development cluster
kind-create:
  kind create cluster --name dev --config setup/kind-dev-cluster.yaml
  # install NGINX Gateway Fabric (for Gateway API)
  # TODO: do this with argo
  kubectl kustomize "https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=v1.6.2" | kubectl apply -f -
  helm install ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric --create-namespace -n nginx-gateway --version 1.6.2 --set service.create=false
  just kind-secrets
  just argocd-install
  just deploy-dev

# delete local development cluster
kind-delete:
  kind delete cluster --name dev

# install cluster secrets to local development cluster
kind-secrets:
  # argo-cd / git deploy key
  kubectl create namespace argocd || true
  ./setup/argocd-deploy-key.sh "kind-dev.$USER.$HOSTNAME"
  read -p "Press Enter to continue"
  # infisical platform auth
  ./setup/infisical-platform-auth.sh dev

# argocd: install
argocd-install:
  # install argocd
  kubectl create namespace argocd || true
  kubectl apply -n argocd -k apps/argocd/envs/dev --wait
  # no matter the env; this will be overruled by just deploy-* later

# deploy prod environment
deploy-prod:
  kubectl config rename-context $(kubectl config current-context) prod || true
  kubectl apply -f appsets/prod.yaml

# deploy dev environment
deploy-dev:
  kubectl apply -f appsets/dev.yaml

fwd-dev-argocd:
  # http://localhost:8080/argocd
  kubectl --context kind-dev port-forward svc/argocd-server -n argocd 8080:80

fwd-prod-argocd:
  # http://localhost:8000/argocd
  kubectl --context prod port-forward svc/argocd-server -n argocd 8000:80

fwd-dev-dagster:
  # http://localhost:8081
  kubectl --context kind-dev port-forward svc/dagster-dagster-webserver -n dagster 8081:80

fwd-prod-dagster:
  # http://localhost:8001
  kubectl --context prod port-forward svc/dagster-dagster-webserver -n dagster 8001:80
