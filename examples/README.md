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
| [`docker/cmatrix/`](docker/cmatrix/) | [03-06 Building Container Images](../notes/03-containers-with-docker/06-building-container-images.md) | Compile cmatrix from source: the single-stage transcript Dockerfile and the final multi-stage, non-root, `ENTRYPOINT`+`CMD` version, to build side by side and compare sizes; buildx multi-platform push |
