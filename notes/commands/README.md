# Commands — per-topic reference

This directory splits the global [`../commands.md`](../commands.md) into focused files, one per tool or task area. Use these when studying or reproducing a single lab; use `../commands.md` when you want one page to `Ctrl+F`.

Both stay in sync — when a chapter adds new commands, update **both** the relevant file here and the global reference.

## Index

Files are created as the course reaches each topic. Planned layout:

| File | What will be in it | Course section |
|---|---|---|
| `setup.md` | Local lab: Docker Desktop / kind / minikube install, kubectl config, aliases | 3, 4 |
| `docker.md` | `docker run/ps/images/build/exec/logs`, image layers, registries | 3 |
| `kubectl-basics.md` | `get/describe/apply/delete/logs/exec`, namespaces, contexts | 4 |
| `workloads.md` | Pods, Deployments, ReplicaSets, DaemonSets, StatefulSets, Jobs | 5 |
| `services-networking.md` | Services, Ingress, DNS, NetworkPolicy | 5 |
| `storage.md` | Volumes, PV/PVC, StorageClasses | 5 |
| `security.md` | RBAC, ServiceAccounts, `auth can-i` | 5 |
| `helm.md` | Repos, install/upgrade/rollback | 5, 7 |
| `observability.md` | `kubectl top`, Prometheus/Grafana access | 6 |
