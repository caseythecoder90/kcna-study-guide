# Observability — kube-prometheus-stack at home

Companion lab for [`06-03 Hands on with Prometheus`](../../notes/06-telemetry-and-observability/03-hands-on-with-prometheus.md), building on [`06-01`](../../notes/06-telemetry-and-observability/01-cloud-native-observability.md) and [`06-02`](../../notes/06-telemetry-and-observability/02-prometheus-and-grafana.md).

| File | What it is |
|---|---|
| [`values-homelab.yaml`](values-homelab.yaml) | Chart values for a small cluster: persistent TSDB, shorter retention, select **all** ServiceMonitors, and k3s control-plane scrapes turned off |
| [`spring-boot-servicemonitor.yaml`](spring-boot-servicemonitor.yaml) | A Service plus a **ServiceMonitor** that scrapes a Spring Boot app's `/actuator/prometheus` |
| [`orders-alerts.yaml`](orders-alerts.yaml) | A **PrometheusRule** with two alerts: 5xx error ratio (counter → `rate()`) and p95 latency (histogram → `histogram_quantile()`) |

## 1. The lecture's install (pinned)

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install my-observability prometheus-community/kube-prometheus-stack --version 55.5.0
kubectl get all -A | grep my-observability
```

## 2. The homelab install

```bash
helm install mon prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace -f values-homelab.yaml
kubectl -n monitoring get pods,pvc
kubectl get crd | grep monitoring.coreos.com             # the operator's CRDs

kubectl -n monitoring port-forward svc/mon-kube-prom-prometheus 9090:9090
kubectl -n monitoring port-forward svc/mon-grafana 3000:80
kubectl -n monitoring get secret mon-grafana -o jsonpath='{.data.admin-password}' | base64 -d; echo
```

Service names follow `<release>-kube-prom-<component>` (the chart abbreviates its own name), except Grafana, kube-state-metrics and node-exporter, which are subcharts: `<release>-grafana`. Check with `kubectl -n monitoring get svc`.

In Prometheus, open **Status → Targets**: every target should be `UP`.

## 3. Scrape your own app

```bash
kubectl create namespace shop
# deploy your Spring Boot app with label app=orders, then:
kubectl apply -f spring-boot-servicemonitor.yaml
kubectl apply -f orders-alerts.yaml
```

After about a minute the app appears under **Status → Targets** as `serviceMonitor/shop/orders/0`. Try:

```promql
sum by (uri) (rate(http_server_requests_seconds_count{job="orders"}[5m]))     # requests/s per endpoint
jvm_memory_used_bytes{job="orders", area="heap"}                             # a gauge
```

The rules show up under **Alerts**. Firing ones reach Alertmanager on port 9093.

## 4. Clean up

```bash
helm uninstall mon -n monitoring
kubectl delete namespace monitoring
kubectl get crd -o name | grep monitoring.coreos.com | xargs kubectl delete    # Helm leaves the CRDs behind
```
