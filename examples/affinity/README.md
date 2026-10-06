# Affinity and anti-affinity

Companion manifests for [`05-07 Affinity and anti-affinity`](../../notes/05-kubernetes-deep-dive/07-affinity-and-anti-affinity.md).

| File | What it does |
|---|---|
| [`node-affinity.yaml`](node-affinity.yaml) | Four Pods: required, impossible-required, weighted-preferred, and node anti-affinity via `NotIn` |
| [`pod-affinity.yaml`](pod-affinity.yaml) | A backend Pod, a frontend that demands to be **with** it, and a batch Pod that demands to be **away** from it |
| [`spread-replicas.yaml`](spread-replicas.yaml) | The real-world use: two Deployments spreading their own replicas, one hard and one soft |
| [`topology-spread.yaml`](topology-spread.yaml) | What anti-affinity cannot express: `maxSkew`, and two constraints at two levels of topology |

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

## The thing anti-affinity could not say

`spread-hard` above left a replica Pending because **required anti-affinity allows only one Pod per domain** — not "one is enough", but *one, full stop*. `spread-soft` placed everything but guaranteed nothing. There is no way to write "spread them out, but two per node is acceptable" with either.

```bash
kubectl apply -f topology-spread.yaml
kubectl get pods -o wide -l app=spreadtest --sort-by=.spec.nodeName
```

```
NAME                              READY   STATUS    NODE
spread-maxskew-xxxxxxxxx-aaaaa    1/1     Running   worker-1
spread-maxskew-xxxxxxxxx-bbbbb    1/1     Running   worker-1
spread-maxskew-xxxxxxxxx-ccccc    1/1     Running   worker-1
spread-maxskew-xxxxxxxxx-ddddd    1/1     Running   worker-2
spread-maxskew-xxxxxxxxx-eeeee    1/1     Running   worker-2
```

**All five running, and 3 + 2 rather than 4 + 1.** `maxSkew: 1` means the busiest domain may hold at most one more matching Pod than the emptiest:

```
skew = matching Pods in THIS domain  -  the global minimum across all domains
```

With 3 and 2, the global minimum is 2, so `worker-1`'s skew is 1 — exactly at the limit. A sixth Pod must go to `worker-2`, or the skew would become 2.

Scale it up and watch the constraint hold:

```bash
kubectl scale deployment/spread-maxskew --replicas=7
kubectl get pods -o wide -l mode=maxskew --sort-by=.spec.nodeName   # 4 + 3
```

### The limitation that bites

```bash
kubectl scale deployment/spread-maxskew --replicas=2
kubectl get pods -o wide -l mode=maxskew --sort-by=.spec.nodeName
```

The two survivors may well both be on `worker-1`. **Constraints are evaluated only when a Pod is scheduled** — *"there's no guarantee that the constraints remain satisfied when Pods are removed."* Nothing rebalances afterwards; that is what the [Descheduler](https://github.com/kubernetes-sigs/descheduler) is for. Same `IgnoredDuringExecution` idea as the rest of the chapter, under a different name again.

### Two levels at once

`spread-two-levels` carries two constraints with the same key appearing once per `whenUnsatisfiable` value — hard per node, soft per zone. **Only one constraint is allowed per `(topologyKey, whenUnsatisfiable)` pair**, so that pairing is the only way to use one key twice.

On a lab cluster with no zone labels, the second constraint has nothing to work with:

```bash
kubectl describe pod -l mode=twolevel | grep -A4 Events
# node(s) didn't match pod topology spread constraints (missing required label)
```

That message is the labelling trap with its own dedicated string. Fake the domains and it resolves:

```bash
kubectl label node/worker-1 topology.kubernetes.io/zone=lab-a
kubectl label node/worker-2 topology.kubernetes.io/zone=lab-b
```

### Ghost pods

Both Deployments here set `mode:` on the Pod template **and** select on it. That is deliberate — a Pod whose own labels do not match its constraint's `labelSelector` **does not count itself**, so such Pods pile onto one node while the scheduler believes nothing has changed. The docs are blunt about it: *"Typically, a pod should match its own topology spread constraint selector."*

```bash
kubectl delete -f topology-spread.yaml
```

## Cleaning up

```bash
kubectl delete -f node-affinity.yaml -f pod-affinity.yaml -f spread-replicas.yaml
kubectl label node/worker-1 disktype- topology.kubernetes.io/zone-
kubectl label node/worker-2 disktype- topology.kubernetes.io/zone-
```
