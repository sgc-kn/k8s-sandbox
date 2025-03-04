This implements the codefresh's gitops model using argocd:
- https://opengitops.dev/
- https://argo-cd.readthedocs.io/
- https://codefresh.io/blog/how-to-model-your-gitops-environments-and-promote-releases-between-them/
- https://codefresh.io/blog/how-to-structure-your-argo-cd-repositories-using-application-sets/

---

Spin up the prod environment on a Ubuntu 24.04 instance:

```shell
just microk8s <cluster ip / fqdn >
just argocd-bootstrap   # follow instructions
just deploy-prod
```

Deploy the dev environment in local minikube cluster:
```shell
minikube delete  # to start from scratch.
minikube start --cpus=4 --memory=8G
just argocd-bootstrap  # follow instructions
just deploy-dev
```
