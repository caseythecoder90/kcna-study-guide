# Commands reference

> Docker, kubectl, and shell commands demonstrated in the hands-on lectures, collected in one page to `Ctrl+F`. The KCNA does not test typing — this exists so the labs are reproducible and so command *names* and *flags* that show up in questions ("which command lists the nodes?") are in one place. For focused per-topic files see [`commands/`](commands/).

## How to use this file

- `Ctrl+F` for the tool or resource (`docker run`, `kubectl get`, ...).
- Sections are added as the course reaches them. Empty sections are placeholders so the numbering is stable.

---

## 1. Local lab setup

_Added when Section 3 (Docker) and Section 4 (Kubernetes) labs begin._

## 2. Docker

_Section 3._

## 3. kubectl basics

_Section 4._

## 4. Workloads and services

_Section 5._

### 4a. Autoscaling (from Section 2, chapter 03)

Full walkthrough: [`commands/autoscaling.md`](commands/autoscaling.md). Example manifest: `examples/autoscaling/hpa-cpu-memory.yaml`.

```bash
# metrics-server (prerequisite for HPA/VPA and kubectl top) — kind needs the insecure-tls flag
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl -n kube-system patch deployment metrics-server --type=json   -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
kubectl top nodes
kubectl top pods

# HPA
kubectl autoscale deployment web --cpu-percent=60 --min=2 --max=10   # CPU only; memory needs v2 YAML
kubectl get hpa
kubectl get hpa web -w
kubectl describe hpa web                                             # Events show each scaling decision

# Load generator
kubectl run -it load --rm --restart=Never --image=busybox:1.36 -- /bin/sh -c "while true; do wget -q -O- http://web; done"
```

## 5. Observability tooling

_Section 6._

## 6. Delivery tooling (Helm, GitOps)

_Section 7._
