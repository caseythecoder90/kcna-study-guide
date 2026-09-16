# Autoscaling — commands

Companion to [`../02-cloud-native-architecture/03-autoscaling.md`](../02-cloud-native-architecture/03-autoscaling.md). Everything here runs on a local kind cluster.

## Prerequisite: metrics-server

The HPA and VPA read CPU/memory usage through the Metrics API, which the metrics-server provides. It is not installed by default on kind or on most kubeadm clusters.

```bash
# Install the latest release
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# kind's kubelets use self-signed certs; tell metrics-server to accept them
kubectl -n kube-system patch deployment metrics-server --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

# Ready when the Metrics API answers
kubectl get apiservice v1beta1.metrics.k8s.io
kubectl top nodes
kubectl top pods
```

## HorizontalPodAutoscaler

```bash
# Apply the CPU + memory example (Deployment + Service + HPA)
kubectl apply -f examples/autoscaling/hpa-cpu-memory.yaml

# Imperative shortcut — CPU only. Memory or multiple metrics need autoscaling/v2 YAML.
kubectl autoscale deployment web --cpu-percent=60 --min=2 --max=10

# Inspect
kubectl get hpa                       # TARGETS shows current/target per metric, e.g. cpu: 3%/60%, memory: 40%/70%
kubectl get hpa web -w                # watch REPLICAS change
kubectl describe hpa web              # Events explain each scaling decision and which metric drove it
kubectl get hpa web -o yaml           # status.currentMetrics, status.conditions

# Generate load from inside the cluster, then watch it scale up
kubectl run -it load --rm --restart=Never --image=busybox:1.36 -- \
  /bin/sh -c "while true; do wget -q -O- http://web; done"
# Ctrl+C the load pod; ~5 minutes later (stabilization window) replicas fall back to min

# Clean up
kubectl delete -f examples/autoscaling/hpa-cpu-memory.yaml
```

Reading `kubectl get hpa` when the metrics-server is missing: TARGETS shows `<unknown>/60%` and `describe` reports `FailedGetResourceMetric`. Fix the metrics-server first.

## VerticalPodAutoscaler (add-on)

```bash
# Not shipped with Kubernetes: install from the kubernetes/autoscaler repo
git clone https://github.com/kubernetes/autoscaler.git
./autoscaler/vertical-pod-autoscaler/hack/vpa-up.sh

kubectl get vpa
kubectl describe vpa <name>           # Recommendation: lower/target/upper bounds for requests
```

## Cluster Autoscaler

Cloud-provider specific (it talks to node groups / instance groups), so there is nothing to run on kind. On a managed cluster it is enabled per node pool — e.g. `eksctl create nodegroup --asg-access`, GKE `--enable-autoscaling`, AKS `--enable-cluster-autoscaler`.
