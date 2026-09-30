# The kube-scheduler

Companion manifests for [`05-05 The kube-scheduler`](../../notes/05-kubernetes-deep-dive/05-kube-scheduler.md).

| File | What it does |
|---|---|
| [`placement.yaml`](placement.yaml) | Five Pods that differ only in how they reach a node: the default path, `nodeSelector`, an impossible `nodeSelector`, a scheduler that is not running, and `nodeName` |
| [`bind-by-hand.sh`](bind-by-hand.sh) | Be your own scheduler, once — write the `Binding` object yourself and watch a Pending Pod start |

```bash
kubectl get nodes                       # pick a real node name
sed -i 's/worker-1/<your-node>/g' placement.yaml
kubectl apply -f placement.yaml
kubectl get pods -o wide
```

## What to look at

```
NAME                 READY   STATUS    NODE
sched-default        1/1     Running   <whichever node scored highest>
sched-nodeselector   1/1     Running   <your-node>
sched-impossible     0/1     Pending   <none>
sched-custom         0/1     Pending   <none>
sched-nodename       1/1     Running   <your-node>
```

**Two Pods are Pending, for completely different reasons.** The distinction is the whole chapter:

```bash
kubectl describe pod sched-impossible | tail -5
# Events:  Warning  FailedScheduling  ... 0/3 nodes are available: 3 node(s)
#          didn't match Pod's node affinity/selector.

kubectl describe pod sched-custom | tail -5
# Events:  <none>
```

`sched-impossible` **was scheduled and rejected** — the scheduler looked at every node, found none feasible, and said so in an event. `sched-custom` has **no events at all**, because kube-scheduler saw `schedulerName: my-scheduler`, decided the Pod was none of its business, and never looked again. Nothing is wrong; nothing is coming either.

## Being the scheduler

```bash
bash bind-by-hand.sh sched-custom
```

```
== The Pod is Pending because nothing claims its schedulerName ==
NAME           STATUS    SCHEDULER      NODE
sched-custom   Pending   my-scheduler   <none>

== Binding default/sched-custom to worker-1 ==
binding/sched-custom created

== spec.nodeName is now set, and the kubelet on worker-1 takes over ==
NAME           STATUS    SCHEDULER      NODE
sched-custom   Running   my-scheduler   worker-1
```

**One API write moved the Pod from Pending to Running**, and the "scheduling algorithm" was `jsonpath='{.items[0].metadata.name}'` — pick the first node. That is genuinely all a scheduler has to do. The course's version loops forever and picks at random instead; [spurin/simple-kubernetes-scheduler-example](https://github.com/spurin/simple-kubernetes-scheduler-example) is about forty lines.

Note `kubectl create`, not `kubectl apply`. **`Binding` is written once, never reconciled** — there is no desired state to converge on, so apply's create-or-update semantics do not fit.

## nodeName versus nodeSelector

Both of these land on the same node, and they are not the same mechanism.

```bash
kubectl get pod sched-nodename -o jsonpath='{.spec.nodeName}{"\n"}'
kubectl describe pod sched-nodename | grep -A3 Events
# Events:  <none>  — except the kubelet's Pulled/Created/Started
```

**No `Scheduled` event.** There is nothing from the `default-scheduler` at all, because it ignored the Pod: `nodeName` was already set, so there was nothing to decide. Compare:

```bash
kubectl describe pod sched-nodeselector | grep -A3 Events
# Normal  Scheduled  ... Successfully assigned default/sched-nodeselector to worker-1
```

**`nodeSelector` went through the scheduler**; `nodeName` skipped it. Which is why an impossible `nodeSelector` waits politely as `Pending`, and a `nodeName` pointing at a node without the resources produces a **failed** Pod with `OutOfcpu` or `OutOfmemory`.

```bash
kubectl delete -f placement.yaml
```
