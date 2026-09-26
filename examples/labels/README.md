# Labels and Selectors

Companion manifest for [`12-labels-and-selectors`](../../notes/04-kubernetes-fundamentals/12-labels-and-selectors.md).

| File | What it is |
|---|---|
| [`coloured-pods.yaml`](coloured-pods.yaml) | Four Pods that differ **only in their labels**, plus a Service whose selector picks a subset of them |

```bash
kubectl apply -f coloured-pods.yaml
kubectl get pods --show-labels
kubectl get pods -L colour -L tier      # labels as COLUMNS rather than a blob
```

| Pod | `colour` | `tier` |
|---|---|---|
| `ubuntu-red` | red | backend |
| `ubuntu-green` | green | frontend |
| `ubuntu-pink` | pink | backend |
| `ubuntu-plain` | *(none)* | backend |

## Both selector grammars

```bash
# equality-based — the only kind a Service can use
kubectl get pods -l colour=red
kubectl get pods -l colour=red,tier=backend      # comma is AND
kubectl get pods -l 'colour!=red'                # ALSO matches ubuntu-plain, which has no colour key

# set-based — Deployments, ReplicaSets, DaemonSets, StatefulSets, Jobs, NetworkPolicies
kubectl get pods -l 'colour in (red,pink)'
kubectl get pods -l colour                       # key exists, any value
kubectl get pods -l '!colour'                    # key does not exist → ubuntu-plain
```

`ubuntu-plain` exists specifically to make the `!=` behaviour visible: **`colour!=red` matches objects with no `colour` label at all**, which surprises people the first time.

## Across kinds

```bash
kubectl get all --selector app=palette
```

Pods and the Service in one result — the same idea as the lecture's `kubectl get all --selector run=nginx`, where `kubectl run` and `kubectl expose` had both stamped `run=nginx` on what they created.

## Relabelling changes ownership

This is the part worth doing slowly. The Service selects `app=palette,tier=backend`:

```bash
kubectl get endpoints palette                    # THREE: red, pink, plain
kubectl label pod ubuntu-green tier=backend --overwrite
kubectl get endpoints palette                    # FOUR — green joined
kubectl label pod ubuntu-red tier-               # trailing - REMOVES a label
kubectl get endpoints palette                    # THREE — red dropped out
```

Nothing about those Pods changed. No restart, no new image, no edit to the Service. A label moved and the membership moved with it — which is exactly how a Service, a ReplicaSet and a NetworkPolicy all decide what they act on.

The addresses show up even though nothing is listening on port 80: endpoint membership is about the **selector matching** and the Pod being **Ready**, not about whether the port works.

```bash
kubectl delete -f coloured-pods.yaml
```
