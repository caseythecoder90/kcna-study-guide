# PodDisruptionBudgets, cordon and drain

Companion manifest for [`05-13 Pod disruption budgets`](../../notes/05-kubernetes-deep-dive/13-pod-disruption-budgets.md). Needs a multi-node cluster (the course's three-node k3s, or kind with workers).

| File | What it does |
|---|---|
| [`nginx-pdb.yaml`](nginx-pdb.yaml) | Five nginx replicas and a `minAvailable: 2` budget |

## 1. cordon moves nothing

```bash
kubectl create deployment nginx --image=nginx --replicas=5
kubectl get pods -o wide
kubectl cordon worker-1
kubectl get nodes                                  # worker-1   Ready,SchedulingDisabled
kubectl get pods -o wide                           # every Pod still where it was
```

Delete the Pods on `worker-1` by hand and the replacements avoid it:

```bash
kubectl delete pod $(kubectl get pods -o name --field-selector spec.nodeName=worker-1 | sed 's#pod/##') --now
kubectl get pods -o wide                           # no new Pod lands on worker-1
kubectl uncordon worker-1
```

## 2. drain without a budget

```bash
kubectl cordon control-plane worker-1              # leave only worker-2 schedulable... then drain it too
kubectl drain worker-2 --ignore-daemonsets --delete-emptydir-data
kubectl get deployment nginx                       # READY 0/5 -- the whole application is down
kubectl uncordon control-plane worker-1 worker-2
kubectl rollout status deployment/nginx
```

Five replicas gave no protection: drain evicted all of them at once.

## 3. drain with a budget

```bash
kubectl delete deployment nginx
kubectl apply -f nginx-pdb.yaml
kubectl rollout status deployment/nginx
kubectl get pdb nginx                              # ALLOWED DISRUPTIONS 3

kubectl drain control-plane worker-1 worker-2 --ignore-daemonsets --delete-emptydir-data --timeout=60s
```

```
pod/nginx-...-z28qz evicted
error when evicting pods/"nginx-...-6sxp2" ... (will retry after 5s):
  Cannot evict pod as it would violate the pod's disruption budget.
```

Three evicted, two refused with HTTP **429**, retried every five seconds. In another terminal:

```bash
kubectl get pdb nginx -w                           # ALLOWED DISRUPTIONS 0
kubectl get deployment nginx                       # READY 2/5 -- still serving
```

Every node is cordoned, so the replacements stay `Pending`, never become Ready, and never free up more budget — the drain gives up at `--timeout`. With spare capacity, each replacement that turns Ready would let the next eviction through.

## 4. What the budget does NOT stop

```bash
kubectl delete pod -l app=nginx                    # deletes all of them -- DELETE bypasses PDBs
kubectl drain worker-2 --ignore-daemonsets --disable-eviction    # also bypasses: plain DELETE
```

Only the Eviction API consults a PDB.

## 5. Budgets that block forever

```bash
kubectl patch pdb nginx --type=merge -p '{"spec":{"minAvailable":5}}'
kubectl get pdb nginx                              # ALLOWED DISRUPTIONS 0
kubectl drain worker-2 --ignore-daemonsets --timeout=30s       # can never succeed
```

`minAvailable` equal to `replicas` (or `maxUnavailable: 0`) means zero voluntary evictions. Switch to `maxUnavailable: 1` — it allows exactly one at a time *and* keeps meaning the same thing if the Deployment is scaled:

```bash
kubectl patch pdb nginx --type=json -p '[{"op":"remove","path":"/spec/minAvailable"},{"op":"add","path":"/spec/maxUnavailable","value":1}]'
```

## Cleaning up

```bash
kubectl uncordon control-plane worker-1 worker-2
kubectl delete -f nginx-pdb.yaml
```
