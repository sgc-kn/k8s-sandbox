ip := `dig +short any.k8s.sandbox.sgckn.pkel.dev`

# configure k8s access
config:
  ssh root@{{ip}} cat  /etc/rancher/k3s/k3s.yaml > $KUBECONFIG
  sed -i "s/127.0.0.1/{{ip}}/" $KUBECONFIG
  kubectl get svc > /dev/null
