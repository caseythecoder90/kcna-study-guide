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

## kube-prometheus-stack (chapter [06-03](../06-telemetry-and-observability/03-hands-on-with-prometheus.md))

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm search repo prometheus-community/kube-prometheus-stack -l                # every version
helm install my-observability prometheus-community/kube-prometheus-stack --version 55.5.0
helm install mon prometheus-community/kube-prometheus-stack -n monitoring --create-namespace -f values.yaml

kubectl get pods -l "release=my-observability"
kubectl get all -A | grep my-observability
kubectl get svc                                                               # 9090 prometheus · 9093 alertmanager · 9100 node-exporter · 80 grafana
kubectl get statefulsets,daemonsets
kubectl get crd | grep monitoring.coreos.com
kubectl get servicemonitors,podmonitors,prometheusrules -A
```

### Access

```bash
kubectl port-forward svc/my-observability-kube-prom-prometheus 9090:9090
kubectl port-forward svc/my-observability-kube-prom-alertmanager 9093:9093
kubectl port-forward svc/my-observability-grafana 3000:80
kubectl get secret my-observability-grafana -o jsonpath='{.data.admin-password}' | base64 -d; echo   # user: admin
```

### Generate something to watch

```bash
for i in {1..10}; do kubectl run nginx${i} --image=nginx; sleep 30; done
for i in {1..10}; do kubectl delete pod nginx${i}; done
```

### PromQL to try

```promql
kube_pod_ips                                                   # kube-state-metrics, one series per Pod
count by (namespace) (kube_pod_info)
sum by (verb) (rate(apiserver_request_total[5m]))
topk(5, sum by (pod) (rate(container_cpu_usage_seconds_total[5m])))
kube_deployment_status_replicas_available < kube_deployment_spec_replicas
up == 0
```

### Remove

```bash
helm uninstall my-observability
kubectl get crd -o name | grep monitoring.coreos.com | xargs kubectl delete   # CRDs survive uninstall
```

## Cost observability (chapter [06-05](../06-telemetry-and-observability/05-cost-management.md))

```bash
# OpenCost, reading the kube-prometheus-stack Prometheus from 06-03 (release "mon" in namespace "monitoring")
helm repo add opencost https://opencost.github.io/opencost-helm-chart
helm repo update
helm install opencost opencost/opencost -n opencost --create-namespace \
  --set opencost.prometheus.internal.namespaceName=monitoring \
  --set opencost.prometheus.internal.serviceName=mon-kube-prom-prometheus \
  --set opencost.prometheus.internal.port=9090
kubectl -n opencost port-forward svc/opencost 9090:9090         # UI on :9090, API on :9003

# Spot capacity
kubectl get nodes -L karpenter.sh/capacity-type,eks.amazonaws.com/capacityType
kubectl taint nodes <spot-node> lifecycle=spot:NoSchedule        # only tolerating workloads land here
kubectl get pdb -A                                               # what a Spot drain must respect
```

## Grafana (chapter [06-04](../06-telemetry-and-observability/04-hands-on-with-grafana.md))

```bash
kubectl port-forward svc/my-observability-grafana 3000:80                                     # http://localhost:3000
kubectl get secret my-observability-grafana -o jsonpath='{.data.admin-user}' | base64 -d; echo
kubectl get secret my-observability-grafana -o jsonpath='{.data.admin-password}' | base64 -d; echo
kubectl get configmaps -A -l grafana_dashboard=1                                               # dashboards loaded by the sidecar
kubectl create configmap orders-dashboard --from-file=orders.json -n shop \
  && kubectl label configmap orders-dashboard grafana_dashboard=1 -n shop                      # ship a dashboard as code
```

```promql
label_values(kube_pod_info, namespace)                       # a dashboard variable query
sum by (namespace) (rate(container_cpu_usage_seconds_total{container!=""}[5m]))
```
