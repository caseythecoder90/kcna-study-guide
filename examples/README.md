# Examples

Runnable Dockerfiles and Kubernetes manifests that accompany [`../notes/`](../notes/), so each concept can be reproduced against a local cluster (kind, minikube, or Docker Desktop).

```bash
kubectl apply -f <file>.yaml
```

## Contents

| Path | Chapter | What it shows |
|---|---|---|
| [`autoscaling/hpa-cpu-memory.yaml`](autoscaling/hpa-cpu-memory.yaml) | [02-03 Autoscaling](../notes/02-cloud-native-architecture/03-autoscaling.md) | A Deployment with resource requests plus an `autoscaling/v2` HorizontalPodAutoscaler targeting 60% CPU and 70% memory utilization, min 2 / max 10. Needs the metrics-server — see [`../notes/commands/autoscaling.md`](../notes/commands/autoscaling.md) |
