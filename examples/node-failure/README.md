# When nodes fail

Companion manifests for [`05-18 When nodes fail`](../../notes/05-kubernetes-deep-dive/18-when-nodes-fail.md). Needs a multi-node cluster where you can stop one node's kubelet: k3s (`systemctl stop k3s-agent` on a worker) or kind (`docker exec <cluster>-worker systemctl stop kubelet`).

| File | What it does |
|---|---|
| [`deployments.yaml`](deployments.yaml) | `default` (injected 300 s tolerations) and `fast` (its own 30 s tolerations) |
| [`statefulset.yaml`](statefulset.yaml) | A one-replica StatefulSet that will **not** be replaced while its old Pod is `Terminating` |

## Set up

```bash
kubectl apply -f deployments.yaml -f statefulset.yaml
kubectl get pods -o wide                       # note which node each Pod is on

# The tolerations every Pod really has
kubectl get pod -l app=default -o jsonpath='{.items[0].spec.tolerations}{"\n"}'   # 300s, injected
kubectl get pod -l app=fast    -o jsonpath='{.items[0].spec.tolerations}{"\n"}'   # 30s, yours
```

If the Pods landed on different nodes, cordon the others and `kubectl rollout restart` until they share one worker, then uncordon.

## Stop the kubelet

```bash
# on the worker (k3s)
systemctl stop k3s-agent.service
# or, for kind
docker exec kind-worker systemctl stop kubelet
```

Watch from the control plane:

```bash
kubectl get nodes -w                            # Ready -> NotReady after ~40-50s
kubectl get pods -o wide -w
```

| Elapsed since the stop | What you see |
|---|---|
| ~50 s | Node `NotReady`. Pods still `1/1 Running` — the columns are stale |
| ~50 s + 30 s | `fast` Pod `Terminating`; replacement scheduled on another node |
| ~50 s + 300 s | `default` Pod `Terminating`; replacement scheduled. `web-0` `Terminating` and **not** replaced |

```bash
kubectl describe node <worker>                  # Ready Unknown, NodeStatusUnknown, unreachable taints
kubectl get pod -l app=default -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}{"\n"}'
kubectl get endpointslices -l kubernetes.io/service-name=web -o yaml | grep -A2 conditions   # ready: false
kubectl get events --field-selector reason=NodeNotReady
```

## Get web-0 back

Either restart the kubelet (the clean path) — or, simulating a node that is gone for good:

```bash
# Only once the node is really powered off
kubectl taint node <worker> node.kubernetes.io/out-of-service=nodeshutdown:NoExecute
kubectl get pods -o wide -w                     # web-0 force-deleted, recreated elsewhere
kubectl taint node <worker> node.kubernetes.io/out-of-service=nodeshutdown:NoExecute-   # remove afterwards
```

## Recover and clean up

```bash
systemctl start k3s-agent.service               # or: docker exec kind-worker systemctl start kubelet
kubectl get pods -o wide                        # the Terminating Pods are gone
kubectl delete -f deployments.yaml -f statefulset.yaml
```
