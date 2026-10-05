# Affinity and anti-affinity

Companion manifests for [`05-07 Affinity and anti-affinity`](../../notes/05-kubernetes-deep-dive/07-affinity-and-anti-affinity.md).

| File | What it does |
|---|---|
| [`node-affinity.yaml`](node-affinity.yaml) | Four Pods: required, impossible-required, weighted-preferred, and node anti-affinity via `NotIn` |
| [`pod-affinity.yaml`](pod-affinity.yaml) | A backend Pod, a frontend that demands to be **with** it, and a batch Pod that demands to be **away** from it |
| [`spread-replicas.yaml`](spread-replicas.yaml) | The real-world use: two Deployments spreading their own replicas, one hard and one soft |

```bash
kubectl label node/worker-1 disktype=ssd
kubectl label node/worker-2 disktype=nvme
kubectl get nodes --show-labels
```

## Required versus preferred, in one `kubectl get`

```bash
kubectl apply -f node-affinity.yaml
kubectl get pods -o wide
```

```
NAME                  READY   STATUS    NODE
affinity-required     1/1     Running   worker-1
affinity-impossible   0/1     Pending   <none>
affinity-preferred    1/1     Running   worker-2
affinity-not-nvme     1/1     Running   worker-1
```

**`affinity-impossible` and `affinity-preferred` are the whole study-tips page.** Both ask for a label; neither gets a perfect match from every node. The required one is **`Pending`** because filtering emptied the feasible set:

```bash
kubectl describe pod affinity-impossible | grep -A4 Events
# FailedScheduling  0/3 nodes are available:
#   3 node(s) didn't match Pod's node affinity/selector.
```

The preferred one **ran anyway** — and it chose `worker-2` because `disktype=nvme` carries `weight: 20` against `ssd`'s `10`. **Delete both labels and `affinity-preferred` still schedules somewhere.** That is "best effort" made concrete.

`affinity-not-nvme` is node *anti*-affinity. There is no `nodeAntiAffinity` field — `NotIn` and `DoesNotExist` are how you express it.

## IgnoredDuringExecution, demonstrated

The half of the field name that nobody reads is easy to prove:

```bash
kubectl label node/worker-1 disktype-              # remove the label that placed it
kubectl get pod affinity-required -o wide          # STILL Running on worker-1
```

**Nothing happened.** Affinity is evaluated once, at scheduling time. Contrast a `NoExecute` taint from chapter 05-06, which evicts immediately. The rule is only reconsidered at the next scheduling decision:

```bash
kubectl replace --force -f node-affinity.yaml      # delete + recreate
kubectl get pods -o wide                           # NOW affinity-required is Pending
kubectl label node/worker-1 disktype=ssd           # put it back
```

This is why the lecture uses `replace --force` rather than `apply` — relabelling a node moves nothing on its own.

## Pods that care about other Pods

```bash
kubectl apply -f pod-affinity.yaml
kubectl get pods -o wide -l 'run in (pod-affinity-backend,pod-affinity-frontend,pod-antiaffinity-batch)'
```

```
NAME                    READY   STATUS    NODE
pod-affinity-backend    1/1     Running   worker-1
pod-affinity-frontend   1/1     Running   worker-1      <- same node, deliberately
pod-antiaffinity-batch  1/1     Running   worker-2      <- different node, deliberately
```

**No node label decided any of this.** The frontend asked to be placed where a Pod labelled `role=backend` already was; the batch Pod asked for the opposite. Delete the backend and recreate the frontend to see the hard version fail:

```bash
kubectl delete pod pod-affinity-backend
kubectl replace --force -f pod-affinity.yaml
kubectl describe pod pod-affinity-frontend | grep -A4 Events
# node(s) didn't match pod affinity rules
```

**A required `podAffinity` rule with nothing to match is just as fatal as an impossible `nodeSelector`.**

### The topologyKey experiment

Change `topologyKey` in `pod-affinity.yaml` from `kubernetes.io/hostname` to `topology.kubernetes.io/zone` and reapply. On a k3s or bare-metal lab cluster, check first:

```bash
kubectl get nodes -L topology.kubernetes.io/zone
```

If that column is empty, **no node is in any zone domain**, and the rule cannot reason about any of them. This is the documented trap: *"Pod anti-affinity requires nodes to be consistently labeled... If some or all nodes are missing the specified `topologyKey` label, it can lead to unintended behavior."*

Label them yourself to simulate zones and watch the placement change with nothing else edited:

```bash
kubectl label node/worker-1 topology.kubernetes.io/zone=lab-a
kubectl label node/worker-2 topology.kubernetes.io/zone=lab-a   # SAME zone
```

With both workers in `lab-a`, the anti-affinity Pod now has nowhere to go — **one domain, already occupied** — where with `kubernetes.io/hostname` it had two domains and a free one. **Same rule, same selector, different meaning of "same place".**

## Spreading replicas

```bash
kubectl apply -f spread-replicas.yaml
kubectl get pods -o wide -l app=spread
```

On a two-worker cluster:

```
NAME                           READY   STATUS    NODE
spread-hard-xxxxxxxxx-aaaaa    1/1     Running   worker-1
spread-hard-xxxxxxxxx-bbbbb    1/1     Running   worker-2
spread-hard-xxxxxxxxx-ccccc    0/1     Pending   <none>      <- 3 replicas, 2 nodes
spread-soft-xxxxxxxxx-ddddd    1/1     Running   worker-1
spread-soft-xxxxxxxxx-eeeee    1/1     Running   worker-2
spread-soft-xxxxxxxxx-fffff    1/1     Running   worker-1
spread-soft-xxxxxxxxx-ggggg    1/1     Running   worker-2
spread-soft-xxxxxxxxx-hhhhh    1/1     Running   worker-1
```

**`required` means a third replica has nowhere legal to go** — every node already holds one, so it waits indefinitely. **`preferred` places all five**, doubling up only once it has to, and evening them out as it goes.

Both Deployments select on **their own Pod label**, which is what makes each replica repel the next. That self-referential selector is the shape worth memorising — it is how a Deployment survives losing a node.

Note the field name inside the soft version: `weight` wraps a **`podAffinityTerm`**, where node affinity's preferred form wraps a **`preference`**.

## Cleaning up

```bash
kubectl delete -f node-affinity.yaml -f pod-affinity.yaml -f spread-replicas.yaml
kubectl label node/worker-1 disktype- topology.kubernetes.io/zone-
kubectl label node/worker-2 disktype- topology.kubernetes.io/zone-
```
