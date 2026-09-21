# Commands — per-topic reference

This directory splits the global [`../commands.md`](../commands.md) into focused files, one per tool or task area. Use these when studying or reproducing a single lab; use `../commands.md` when you want one page to `Ctrl+F`.

Both stay in sync — when a chapter adds new commands, update **both** the relevant file here and the global reference.

## Index

Files are created as the course reaches each topic. Planned layout:

| File | What will be in it | Course section |
|---|---|---|
| `docker.md` | `docker run/ps/images/build/exec/logs`, image layers, registries | 3 |
| `workloads.md` | Pods, Deployments, ReplicaSets, DaemonSets, StatefulSets, Jobs | 5 |
| `services-networking.md` | Services, Ingress, DNS, NetworkPolicy | 5 |
| `storage.md` | Volumes, PV/PVC, StorageClasses | 5 |
| `security.md` | RBAC, ServiceAccounts, `auth can-i` | 5 |
| `helm.md` | Repos, install/upgrade/rollback | 5, 7 |
| `observability.md` | `kubectl top`, Prometheus/Grafana access | 6 |

## Written so far

| File | What's in it | Chapter |
|---|---|---|
| [`autoscaling.md`](autoscaling.md) | metrics-server install on kind, `kubectl autoscale`, inspecting an HPA, generating load, VPA install, where the Cluster Autoscaler lives | [02-03](../02-cloud-native-architecture/03-autoscaling.md) |
| [`setup.md`](setup.md) | Docker Desktop install checks, enabling its Kubernetes and querying the node, Docker Engine on Linux | [03-02](../03-containers-with-docker/02-docker-setup-and-install.md) |
| [`kubectl-basics.md`](kubectl-basics.md) | Seeing the architecture: nodes, the control plane as Pods, static vs normal Pods and their owners, mirror-pod behaviour, `/etc/kubernetes/manifests`, etcd member list, watching a Pod get scheduled, the REST API behind kubectl | [04-01](../04-kubernetes-fundamentals/01-container-orchestration-and-architecture.md) |
| [`docker.md`](docker.md) | **The Docker command reference**: images, containers (run flags, lifecycle, exec/logs/inspect), networks, volumes, build and buildx multi-platform, push, Dockerfile rules, compose, cross-platform notes, plus the Section 3 lab blocks | [03-04](../03-containers-with-docker/04-running-containers.md) · [03-06](../03-containers-with-docker/06-building-container-images.md) |
