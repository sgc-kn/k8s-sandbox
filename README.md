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

Deploy the dev environment in local docker/podman/nerdctl cluster:
```shell
just kind-delete # to start from scratch
just kind-create # follow instructions
```
Note, this requires some kernel configs. Otherwise you will likely run
into inotify resource limits. [See kind FAQ][inotify].

[inotify]: https://kind.sigs.k8s.io/docs/user/known-issues/#pod-errors-due-to-too-many-open-files
