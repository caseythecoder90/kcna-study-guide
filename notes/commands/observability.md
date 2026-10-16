# Observability — commands

Companion to section 6: [`06-01 Cloud native observability`](../06-telemetry-and-observability/01-cloud-native-observability.md). Extended as the section continues.

## `kubectl top` (needs the Metrics Server)

```bash
kubectl top node                                   # NAME  CPU(cores)  CPU%  MEMORY(bytes)  MEMORY%
kubectl top pod                                    # current namespace
kubectl top pod -A                                 # all namespaces
kubectl top pod --sort-by=cpu                      # or --sort-by=memory
kubectl top pod -l app=web                         # by label
kubectl top pod <pod> --containers                 # one line per container
kubectl top pod --help
```

CPU in millicores (`250m` = a quarter core), memory in Mi. Percentages are of the node's **allocatable** capacity.

## The Metrics API behind it

```bash
kubectl get apiservice v1beta1.metrics.k8s.io      # AVAILABLE must be True
kubectl -n kube-system get deploy metrics-server
kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes | jq .                          # NodeMetrics
kubectl get --raw /apis/metrics.k8s.io/v1beta1/namespaces/default/pods | jq .         # PodMetrics
kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes | jq '.items[] | {node: .metadata.name, usage}'
```

Installing the Metrics Server (kind and kubeadm clusters don't ship it): see [`autoscaling.md`](autoscaling.md#prerequisite-metrics-server).

`error: Metrics API not available` means the Metrics Server is missing or its APIService is not Available. The HPA shows `<unknown>` targets for the same reason.

## Logs (the first pillar, from Kubernetes)

```bash
kubectl logs <pod> [-c <container>] [-f] [--tail=50] [--since=10m] [-p]   # -p = previous (crashed) container
kubectl logs -l app=web --all-containers --prefix                          # many Pods at once
ls /var/log/pods/                                                          # on the node: where the runtime writes stdout/stderr
```
