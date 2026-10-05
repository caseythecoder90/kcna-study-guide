# Taints and tolerations

Companion manifests for [`05-06 Taints and tolerations`](../../notes/05-kubernetes-deep-dive/06-taints-and-tolerations.md).

| File | What it does |
|---|---|
| [`test-taint.yaml`](test-taint.yaml) | The lecture's Deployment: a `nodeSelector` pointed at one node, plus one toleration per taint on it |
| [`tolerate-everything.yaml`](tolerate-everything.yaml) | The special-case matching rules — empty key, empty effect, and `tolerationSeconds` |

```bash
kubectl get nodes                                  # pick a real worker
sed -i 's/worker-2/<your-node>/g' test-taint.yaml
```

## First, look at what is already there

```bash
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
```

On a **kubeadm** cluster the control-plane row shows `node-role.kubernetes.io/control-plane:NoSchedule`. On **k3s**, **MicroK8s** or **kind** it usually shows `<none>` — the lightweight distributions remove the taint during setup or never apply it, because a tainted single-node cluster would have nowhere to run anything.

That one difference is also why a DaemonSet covers every node on one cluster and appears to skip the control plane on another (chapter 04-06).

## The four states

**State 1 — nodeSelector alone is not enough.** Comment out the whole `tolerations:` block, then:

```bash
kubectl taint nodes worker-2 custom-taint1=lenient:NoSchedule
kubectl apply -f test-taint.yaml
kubectl get pods -o wide
```

```
NAME                          READY   STATUS    NODE
test-taint-5987d59468-kdntx   0/1     Pending   <none>
```

```bash
kubectl describe pod -l app=test-taint | grep -A4 Events
# FailedScheduling  0/3 nodes are available:
#   1 node(s) had untolerated taint {custom-taint1: lenient},
#   2 node(s) didn't match Pod's node affinity/selector.
```

**Read that event carefully — it names both filters.** `nodeSelector` eliminated two nodes for not matching; the taint eliminated the third for not being tolerated. **Attraction and permission are separate, and the Pod needs both.** Note the status is `Pending`, not `Failed`: the scheduler retries forever, so fixing either filter resolves it with no restart.

**State 2 — uncomment the first toleration.**

```bash
kubectl apply -f test-taint.yaml
kubectl get pods -o wide        # Running on worker-2
```

Nothing attracted the Pod here. `nodeSelector` had already chosen the node and was being blocked; the toleration only removed the objection. `operator: Exists` means "any value for this key", which is why `lenient` appears nowhere in the manifest.

**State 3 — a NoExecute taint, with the Pod already running.**

```bash
kubectl taint node worker-2 custom-taint2=strict:NoExecute
kubectl get pods -o wide
```

```
NAME                          READY   STATUS    NODE
test-taint-5987d59468-kdntx   0/1     Pending   <none>
```

**Two separate things happened.** The running Pod was **evicted**, because it did not tolerate the new taint and `NoExecute` acts on Pods already on the node. Then the ReplicaSet created a **replacement**, which cannot be scheduled either — the same un-ignored taint blocks placement.

Had the taint been `NoSchedule`, the first Pod would **still be running**. That is the whole `NoSchedule`/`NoExecute` distinction, visible in one command.

**State 4 — uncomment the second toleration.**

```bash
kubectl apply -f test-taint.yaml
kubectl get pods -o wide        # Running on worker-2 again
```

Two tolerations, two taints, nothing left un-ignored. Note the contrast between them: the first uses `Exists` and omits `value`; the second uses `Equal` and must spell out `strict`.

## The special cases

```bash
kubectl apply -f tolerate-everything.yaml
kubectl get pods -o wide
```

`tolerate-all-noschedule` has **no key** — which, with `operator: Exists`, matches **all keys and values**. The effect still has to match, so it tolerates every `NoSchedule` taint in the cluster. On a kubeadm cluster, watch where it lands: it is eligible for the control-plane node.

`tolerate-everything` drops the effect too, which matches **all effects**. Empty key, empty effect, `Exists` — it tolerates every taint on every node. This is the blanket toleration a cluster-wide DaemonSet uses, and it is also how you accidentally schedule onto a node that was tainted for a good reason.

`tolerate-for-a-minute` demonstrates `tolerationSeconds`:

```bash
kubectl taint nodes worker-2 custom-taint2=strict:NoExecute
# ...wait and watch
kubectl get pod tolerate-for-a-minute -w
```

It stays bound for 60 seconds after the taint appears, then the controller evicts it. **Remove the taint before the time elapses and it is never evicted.** `tolerationSeconds` means nothing on a `NoSchedule` toleration — there is nothing to count down for an effect that never evicts.

## Cleaning up

```bash
kubectl taint nodes worker-2 custom-taint1=lenient:NoSchedule-
kubectl taint nodes worker-2 custom-taint2=strict:NoExecute-
kubectl delete -f test-taint.yaml -f tolerate-everything.yaml
```

The **trailing dash** is how a taint is removed: the same `key=value:effect` string with `-` appended.
