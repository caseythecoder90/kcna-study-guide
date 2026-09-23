# Pods

Companion manifests for [`02-pods`](../../notes/04-kubernetes-fundamentals/02-pods.md). Both run on any cluster — kind, minikube, Docker Desktop, k3s.

| File | What it shows |
|---|---|
| [`sidecar-pod.yaml`](sidecar-pod.yaml) | Two containers in one Pod: nginx plus an ubuntu sidecar reachable over `localhost`, with a `/tmp/crash` switch so you can fail one container and watch the other survive |
| [`countdown-pod.yaml`](countdown-pod.yaml) | An init container that counts 120 down to 0 before the app container is allowed to start — two minutes of `STATUS Init:0/1` |

## Both at once

A YAML file can hold any number of objects separated by `---`, so the two can be concatenated into one artifact:

```bash
{ cat sidecar-pod.yaml; echo "---"; cat countdown-pod.yaml; } | tee combined.yaml
kubectl apply -f combined.yaml
kubectl delete -f combined.yaml
```

The trailing `;` before `}` is required in `sh`/`bash`. `kubectl apply -f sidecar-pod.yaml -f countdown-pod.yaml` and `kubectl apply -f .` do the same job without the concatenation.
