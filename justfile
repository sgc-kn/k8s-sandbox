host := "any.k8s.sandbox.sgckn.pkel.dev"

# update the argocd installation on the cluster
update: argocd

# run all commands for setting up the cluster
setup: cluster config letsencrypt argocd

# configure local k8s access
config:
  ssh root@{{host}} microk8s config > $KUBECONFIG
  kubectl get svc > /dev/null

# configure remote k8s cluster (ubuntu, microk8s)
cluster:
  ssh root@{{host}} snap install microk8s --channel=latest/edge/strict
  ssh root@{{host}} microk8s start
  ssh root@{{host}} microk8s enable cert-manager
  ssh root@{{host}} microk8s enable dns
  ssh root@{{host}} microk8s enable hostpath-storage
  ssh root@{{host}} microk8s enable ingress
  ssh root@{{host}} microk8s status --wait-ready

# configure letsencrypt cluster issuers
letsencrypt:
  kubectl apply -f shared/clusterissuer-letsencrypt-prod.yaml
  kubectl apply -f shared/clusterissuer-letsencrypt-staging.yaml

# setup or update argocd
argocd:
  kubectl create namespace argocd || true
  kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
  kubectl apply -n argocd -f ingress/argocd-server.yaml
  sleep 1
  argocd admin initial-password -n argocd
