# Kustomize

Companion lab for [`05-22 Kustomize`](../../notes/05-kubernetes-deep-dive/22-kustomize.md). One base, two overlays. The base is never edited.

| Path | What it is |
|---|---|
| [`base/`](base/) | An nginx Deployment and Service, plus a `kustomization.yaml` listing them. Valid on its own |
| [`overlays/dev/`](overlays/dev/) | Namespace `dev`, prefix `dev-`, label `env=dev`, and a newer image tag through `images:` |
| [`overlays/prod/`](overlays/prod/) | Namespace `prod`, prefix `prod-`, 3 replicas through `replicas:`, and a strategic-merge patch adding resource requests and limits |

```bash
kubectl kustomize base                         # the plain manifests
kubectl kustomize overlays/dev                 # same manifests, renamed, relabelled, retagged
diff <(kubectl kustomize overlays/dev) <(kubectl kustomize overlays/prod)

kubectl create namespace dev && kubectl create namespace prod
kubectl apply -k overlays/dev
kubectl apply -k overlays/prod
kubectl get deploy,svc -A -l app=web -L env    # dev-web (1 replica) and prod-web (3 replicas)

kubectl diff -k overlays/prod                  # nothing to change
kubectl delete -k overlays/dev
kubectl delete -k overlays/prod
```

Things to notice in the rendered output:

- `namePrefix` renamed the Service **and** nothing broke: the Service selector uses labels, not names, and Kustomize rewrites name references it knows about (ConfigMap and Secret refs, for example).
- `labels:` added `env` to `metadata.labels` only. The selector still reads `app: web`, so the overlay never changes an immutable Deployment selector.
- `replicas[].name` and the patch's `metadata.name` both say `web`, the **base** name, not `prod-web`.
