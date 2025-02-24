host := "any.k8s.sandbox.sgckn.pkel.dev"

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

# configure whoami (test deployment)
whoami:
  kubectl apply -f letsencrypt-prod.yaml
  kubectl apply -f whoami-deployment.yaml
  kubectl apply -f whoami-service.yaml
  kubectl apply -f whoami-ingress.yaml

# configure argocd
argocd:
  kubectl create namespace argocd || true
  kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
  kubectl apply -f argocd-server-http-ingress.yml
  sleep 1
  argocd admin initial-password -n argocd
