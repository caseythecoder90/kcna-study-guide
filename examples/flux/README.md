# Flux

Companion lab for [`07-04 Flux and the GitOps Toolkit`](../../notes/07-cloud-native-application-delivery/04-flux-and-the-gitops-toolkit.md).

| File | What it is |
|---|---|
| [`podinfo.yaml`](podinfo.yaml) | A `GitRepository` (source-controller) and a Flux `Kustomization` (kustomize-controller) that deploy the public podinfo app with pruning and health checks |

## 1. Quick look, no bootstrap

```bash
brew install fluxcd/tap/flux            # or: curl -s https://fluxcd.io/install.sh | sudo bash
flux check --pre
flux install                            # controllers into flux-system, no Git repo of its own
kubectl -n flux-system get pods         # source-, kustomize-, helm-, notification-controller

kubectl apply -f podinfo.yaml
flux get sources git -A                 # REVISION master@sha1:...
flux get kustomizations -A              # READY True
kubectl get deploy,svc,hpa podinfo

kubectl scale deploy podinfo --replicas=5          # drift
flux reconcile kustomization podinfo -n flux-system   # or wait up to 2 minutes: back to the HPA-managed count
flux tree kustomization podinfo -n flux-system
```

## 2. The real way: bootstrap into your own repo

```bash
export GITHUB_TOKEN=<personal access token> GITHUB_USER=<you>
flux bootstrap github --owner=$GITHUB_USER --repository=fleet-infra \
  --branch=main --path=./clusters/homelab --personal
```

Then commit `podinfo.yaml` (or your own apps) under `clusters/homelab/` in `fleet-infra` and push. Flux applies it within the interval, and `flux reconcile source git flux-system` makes it immediate.

## 3. Clean up

```bash
kubectl delete -f podinfo.yaml           # prune: true removes the podinfo objects too
flux uninstall
```
