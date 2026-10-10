# Helm — commands

Companion to [`../05-kubernetes-deep-dive/21-helm.md`](../05-kubernetes-deep-dive/21-helm.md). Helm is a client-side binary: it renders charts on your machine and talks to the API server with your kubeconfig. Section 7 (delivery) will extend this file.

## Install the client

```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
chmod 700 get_helm.sh && ./get_helm.sh
brew install helm                   # macOS
winget install Helm.Helm            # Windows
sudo snap install helm --classic    # Linux
helm version
```

## Find charts: hub vs repository

```bash
helm search hub nginx                          # Artifact Hub — the cross-repository index
helm search hub nginx --list-repo-url          # ...with the repository URL to add
helm repo add podinfo https://stefanprodan.github.io/podinfo
helm repo update                               # refresh every added repo's index.yaml
helm repo list
helm search repo podinfo                       # only repos you have added, from the cached index
helm search repo podinfo --versions            # every chart version
helm repo remove podinfo
```

## Inspect before installing

```bash
helm show chart  podinfo/podinfo               # Chart.yaml: version, appVersion
helm show values podinfo/podinfo > values.yaml # the defaults, to copy and edit
helm show readme podinfo/podinfo
helm pull podinfo/podinfo --untar              # download the chart source
helm template web podinfo/podinfo -f values.yaml   # render the manifests locally, apply nothing
```

## Install, upgrade, roll back, remove

```bash
helm install web podinfo/podinfo -n web --create-namespace -f values.yaml
helm install web podinfo/podinfo --version 6.15.0 --set replicaCount=2
helm install web oci://ghcr.io/stefanprodan/charts/podinfo        # straight from an OCI registry
helm upgrade --install web podinfo/podinfo -n web -f values.yaml  # install if absent, else upgrade
helm upgrade web podinfo/podinfo -n web --set replicaCount=3       # new revision
helm rollback web 1 -n web                                         # new revision with revision 1's content
helm uninstall web -n web                       # aliases: un, del, delete; removes resources AND history
helm uninstall web -n web --keep-history        # keep the record (status: uninstalled)
```

Values precedence, lowest to highest: chart `values.yaml` → parent chart values → `-f` files (last wins) → `--set`.

## Inspect releases

```bash
helm list                       # current namespace
helm list -A                    # all namespaces
helm list -a                    # include failed / uninstalled-with-history
helm status web -n web
helm history web -n web         # REVISION  STATUS  CHART  APP VERSION  DESCRIPTION
helm get values web -n web      # values supplied by the user (--all for merged)
helm get manifest web -n web    # the rendered YAML that was applied
kubectl get secrets -n web -l owner=helm        # sh.helm.release.v1.web.v1, .v2 ...
```

## Author and package a chart

```bash
helm create flappy-app          # scaffold: Chart.yaml, values.yaml, charts/, templates/, .helmignore
helm lint ./flappy-app
helm template ./flappy-app      # see exactly what would be applied
helm install flappy-app ./flappy-app --dry-run=server   # render + validate against the API server
helm package ./flappy-app       # → flappy-app-<version>.tgz (version from Chart.yaml)
helm install flappy-app flappy-app-0.1.0.tgz
helm test flappy-app            # runs templates/tests/ Pods
helm dependency update ./flappy-app            # fetch charts listed under dependencies into charts/
```

## Share a chart

```bash
helm registry login ghcr.io
helm push flappy-app-0.1.0.tgz oci://ghcr.io/<user>/charts          # OCI registry
helm repo index . --url https://<user>.github.io/charts             # classic repo: generate index.yaml
```
