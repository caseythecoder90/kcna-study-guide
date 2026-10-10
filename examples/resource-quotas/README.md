# Resource quotas

Companion manifests for [`05-17 Resource quotas`](../../notes/05-kubernetes-deep-dive/17-resource-quotas.md).

| File | What it does |
|---|---|
| [`quota.yaml`](quota.yaml) | Namespace `limited` and the lecture's quota |
| [`pods.yaml`](pods.yaml) | Three Pods that fit — 750m / 768Mi requested in total |
| [`over-quota.yaml`](over-quota.yaml) | A fourth Pod — fits every CPU and memory total, rejected by count |
| [`millibytes.yaml`](millibytes.yaml) | The `400m` memory trap |
| [`no-resources.yaml`](no-resources.yaml) | A Pod with no `resources` — rejected outright |
| [`limitrange.yaml`](limitrange.yaml) | Defaults that make the bare Pod admissible |

## The ledger

```bash
kubectl apply -f quota.yaml
kubectl describe quota limited -n limited          # Used 0 against every Hard
kubectl apply -f pods.yaml
kubectl describe quota limited -n limited
```

```
Resource         Used    Hard
--------         ----    ----
limits.cpu       1500m   2
limits.memory    1536Mi  2Gi
pods             3       3
requests.cpu     750m    1
requests.memory  768Mi   1Gi
```

## Rejected at admission

```bash
kubectl apply -f over-quota.yaml
# Error from server (Forbidden): ... pods "pod4" is forbidden: exceeded quota: limited,
#   requested: pods=1, used: pods=3, limited: pods=3
kubectl get pods -n limited                        # still three -- pod4 was never stored
```

**403 Forbidden from the API server — not the kubelet.** The Pod never existed, so the scheduler never saw it.

```bash
kubectl apply -f no-resources.yaml
# ... failed quota: limited: must specify limits.cpu for: bare; limits.memory for: bare; ...
kubectl apply -f limitrange.yaml
kubectl delete pod pod3 -n limited                 # free a slot
kubectl apply -f no-resources.yaml                 # admitted now -- defaults injected
kubectl get pod bare -n limited -o jsonpath='{.spec.containers[0].resources}'
```

## The memory trap

```bash
kubectl delete pod bare -n limited                 # free a slot
kubectl apply -f millibytes.yaml                   # pod/millibytes created
kubectl get pod millibytes -n limited -o jsonpath='{.spec.containers[0].resources.requests.memory}'
# 400m      <- 0.4 bytes. The API accepted it; the container can do nothing with it.
kubectl get pod millibytes -n limited -w           # watch it: the limit rounds up to ONE byte -- nothing can run in that
```

`m` is a legal quantity suffix because memory and CPU share one quantity format. For CPU it is exactly right (millicores); for memory it is almost always a typo for `Mi`.

## Lowering a quota evicts nothing

```bash
kubectl patch resourcequota limited -n limited --type=merge -p '{"spec":{"hard":{"pods":"1"}}}'
kubectl get pods -n limited                        # everything still Running
kubectl describe quota limited -n limited          # pods  Used 3  Hard 1
kubectl apply -f over-quota.yaml                   # rejected: pods Used already exceeds Hard
```

"Neither contention nor changes to quota will affect already created resources."

## Cleaning up

```bash
kubectl delete namespace limited
```
