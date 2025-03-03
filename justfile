host := "any.k8s.sandbox.sgckn.pkel.dev"

# deploy to fresh cluster
bootstrap: cluster config argocd

# configure remote k8s cluster (ubuntu, microk8s)
cluster:
  ssh root@{{host}} snap install microk8s --channel=latest/edge/strict
  ssh root@{{host}} microk8s start
  ssh root@{{host}} microk8s enable cert-manager
  ssh root@{{host}} microk8s enable dns
  ssh root@{{host}} microk8s enable hostpath-storage
  ssh root@{{host}} microk8s enable ingress
  ssh root@{{host}} microk8s status --wait-ready

# configure local k8s access
config:
  ssh root@{{host}} microk8s config > $KUBECONFIG
  kubectl get svc > /dev/null

# bootstrap argocd
argocd:
  # install argocd
  kubectl create namespace argocd || true
  kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

  # configure access to private repo
  bash setup-deploy-key.sh
  read -p "Press Enter to continue"

  # print admin's password
  argocd admin initial-password -n argocd

# deploy all resources the app-of-apps pattern
app-of-apps:
  kubectl apply -f app-of-apps/app-of-apps.yaml

# forward argocd-server to http://localhost:8080
fwd-argocd:
  kubectl port-forward svc/argocd-server -n argocd 8080:80

# forward dagster-webserver to http://localhost:8081
fwd-dagster:
  #!/usr/bin/env bash
  set -euxo pipefail
  pod=`kubectl get pods --namespace dagster -l "app.kubernetes.io/name=dagster,app.kubernetes.io/instance=dagster,component=dagster-webserver" -o jsonpath="{.items[0].metadata.name}"`
  kubectl --namespace dagster port-forward $pod 8081:80
