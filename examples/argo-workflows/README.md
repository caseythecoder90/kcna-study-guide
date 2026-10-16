# Argo Workflows

Companion lab for [`07-03 Argo Workflows and the Argo family`](../../notes/07-cloud-native-application-delivery/03-argo-workflows-and-the-argo-family.md).

| File | What it is |
|---|---|
| [`parallel-dag.yaml`](parallel-dag.yaml) | A CI-shaped DAG: `checkout`, then `unit-tests`, `lint` and `security-scan` **in parallel**, then `build-image` once all three finish |

```bash
kubectl create namespace argo
kubectl apply -n argo -f https://github.com/argoproj/argo-workflows/releases/download/v4.1.5/quick-start-minimal.yaml
kubectl -n argo rollout status deploy/workflow-controller

argo submit -n argo --watch parallel-dag.yaml      # or: kubectl create -n argo -f parallel-dag.yaml
kubectl -n argo get pods                           # three test Pods running at the same time
argo get -n argo @latest
argo logs -n argo @latest

kubectl -n argo port-forward svc/argo-server 2746:2746   # UI: https://localhost:2746 (accept the self-signed cert)

kubectl delete namespace argo                      # clean up
```

`kubectl create`, not `apply`: `generateName` needs create. The quick-start manifests are for learning, not production.
