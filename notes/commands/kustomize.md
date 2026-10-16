# Kustomize — commands

Companion to [`../05-kubernetes-deep-dive/22-kustomize.md`](../05-kubernetes-deep-dive/22-kustomize.md). Kustomize is built into kubectl; nothing to install. Runnable lab: [`examples/kustomize/`](../../examples/kustomize/).

## Render, apply, diff, delete

```bash
kubectl kustomize overlays/prod                # render to stdout — always look before applying
kubectl kustomize overlays/prod > out.yaml     # save the rendered manifests
kubectl apply -k overlays/prod                 # render + apply
kubectl diff -k overlays/prod                  # what apply would change
kubectl delete -k overlays/prod                # render + delete
kubectl version --client                       # Client Version + Kustomize Version
```

`-k` takes the **directory** that holds `kustomization.yaml`, and you point it at the **overlay**. `kubectl apply -f <dir>` would apply the raw files and ignore the kustomization.

## Remote kustomizations

```bash
# A Git URL, pinned to a tag (chapter 05-12 installed the Gateway API CRDs this way)
kubectl kustomize "https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=v2.3.0" | kubectl apply -f -
```

## Layout and fields

```
base/            deployment.yaml  service.yaml  kustomization.yaml
overlays/dev/    kustomization.yaml (+ patches)
overlays/prod/   kustomization.yaml (+ patches)
```

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources: [../../base]
namespace: prod
namePrefix: prod-
labels:
  - pairs: {env: prod}            # metadata.labels only; commonLabels also edits selectors
commonAnnotations: {owner: web}
images:
  - name: nginx                   # the IMAGE name, not the container name
    newTag: "1.27"
replicas:
  - name: web                     # the BASE name, before namePrefix
    count: 3
patches:
  - path: resources-patch.yaml    # strategic merge: a partial manifest
configMapGenerator:
  - name: app-config
    literals: [LOG_LEVEL=info]    # name gets a content-hash suffix; references are rewritten
```

The CKAD-depth reference (JSON 6902 paths, list and map operations, components, generator options) is in the [CKAD notes](https://github.com/caseythecoder90/ckad-exam-prep/tree/main/notes/11-kustomize).
