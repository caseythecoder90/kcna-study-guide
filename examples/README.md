# Examples

Runnable Dockerfiles and Kubernetes manifests that accompany [`../notes/`](../notes/), so each concept can be reproduced against a local cluster (kind, minikube, or Docker Desktop).

```bash
kubectl apply -f <file>.yaml
```

## Contents

| Path | Chapter | What it shows |
|---|---|---|
| [`autoscaling/hpa-cpu-memory.yaml`](autoscaling/hpa-cpu-memory.yaml) | [02-03 Autoscaling](../notes/02-cloud-native-architecture/03-autoscaling.md) | A Deployment with resource requests plus an `autoscaling/v2` HorizontalPodAutoscaler targeting 60% CPU and 70% memory utilization, min 2 / max 10. Needs the metrics-server — see [`../notes/commands/autoscaling.md`](../notes/commands/autoscaling.md) |
| [`docker/nginx-bind-mount/`](docker/nginx-bind-mount/) | [03-05 Networking and Volumes](../notes/03-containers-with-docker/05-networking-and-volumes.md) | Stock `nginx` serving a bind-mounted `index.html` read-only on published port 12345; run commands for bash, PowerShell and cmd, plus volume and `-P` variants |
| [`pods/sidecar-pod.yaml`](pods/sidecar-pod.yaml) | [04-02 Pods](../notes/04-kubernetes-fundamentals/02-pods.md) | Two containers in one Pod sharing one IP and one network namespace: nginx plus an ubuntu sidecar that reaches it on `localhost`, with a `/tmp/crash` switch so you can fail one container and watch the other survive |
| [`pods/countdown-pod.yaml`](pods/countdown-pod.yaml) | [04-02 Pods](../notes/04-kubernetes-fundamentals/02-pods.md) | An init container counting 120 down to 0 before the app container may start — two minutes of `STATUS Init:0/1`, then `Running`. See [`pods/README.md`](pods/README.md) |
| [`pods/broken-pods.yaml`](pods/broken-pods.yaml) | [04-03 Troubleshooting Pods](../notes/04-kubernetes-fundamentals/03-troubleshooting-pods.md) | Five Pods that each fail in a different way — unschedulable, `InvalidImageName`, `ImagePullBackOff`, `CrashLoopBackOff`, `RunContainerError` — so every status from the chapter shows up side by side in one `kubectl get pods` |
| [`docker/cmatrix/`](docker/cmatrix/) | [03-06 Building Container Images](../notes/03-containers-with-docker/06-building-container-images.md) | Compile cmatrix from source: the single-stage transcript Dockerfile and the final multi-stage, non-root, `ENTRYPOINT`+`CMD` version, to build side by side and compare sizes; buildx multi-platform push |
