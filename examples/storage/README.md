# Kubernetes storage

Companion manifests for [`05-08 Kubernetes storage`](../../notes/05-kubernetes-deep-dive/08-kubernetes-storage.md). Written for **k3s**, which ships the `local-path` StorageClass; on another distribution, change `storageClassName` and the `hostPath` directory.

| File | What it does |
|---|---|
| [`emptydir-memory.yaml`](emptydir-memory.yaml) | Ephemeral storage in RAM — a tmpfs `emptyDir` with a memory limit and a `sizeLimit` |
| [`static-pv.yaml`](static-pv.yaml) | Static provisioning: a `hostPath` PV and a claim pre-bound to it with `volumeName` |
| [`dynamic-pvc.yaml`](dynamic-pvc.yaml) | Dynamic provisioning: just the claim |
| [`pod-both-volumes.yaml`](pod-both-volumes.yaml) | One Pod mounting both claims, pinned with `nodeSelector` |

```bash
kubectl get storageclass
# local-path (default)   rancher.io/local-path   Delete   WaitForFirstConsumer   false
```

## Ephemeral: which restart?

```bash
kubectl apply -f emptydir-memory.yaml
kubectl exec ubuntu-cache -- sh -c 'df -h /cache; echo kept > /cache/test'
# Filesystem  Size  ...  tmpfs  ... /cache
```

**Container restart — the file survives.** The container exits as soon as `/tmp/crash` exists, so the kubelet restarts it inside the same Pod:

```bash
kubectl exec ubuntu-cache -- touch /tmp/crash
kubectl get pod ubuntu-cache -w       # RESTARTS 1
kubectl exec ubuntu-cache -- cat /cache/test    # kept
```

Note what happened to `/tmp/crash` itself: it is **gone**, because `/tmp` is on the container's writable layer. One restart, two files, two outcomes — the writable layer and `emptyDir` side by side.

**Pod restart — the file is gone.**

```bash
kubectl delete pod ubuntu-cache
kubectl apply -f emptydir-memory.yaml
kubectl exec ubuntu-cache -- cat /cache/test    # No such file or directory
```

That is the precise meaning of "ephemeral storage does not survive restarts": **a container crash does not remove a Pod from a node**, so `emptyDir` survives it. Only the Pod leaving the node deletes the data.

## Persistent: static and dynamic

```bash
kubectl apply -f static-pv.yaml -f dynamic-pvc.yaml
kubectl get pv,pvc
```

```
NAME                            CAPACITY   RECLAIM POLICY   STATUS   CLAIM
persistentvolume/manual-pv001   10Gi       Retain           Bound    default/manual-claim

NAME                                  STATUS    VOLUME         STORAGECLASS
persistentvolumeclaim/manual-claim    Bound     manual-pv001   local-path
persistentvolumeclaim/dynamic-claim   Pending                  local-path
```

**`dynamic-claim` is `Pending` and that is correct.** The class is `WaitForFirstConsumer`, so nothing is provisioned until a Pod uses it:

```bash
kubectl describe pvc dynamic-claim | tail -3
# waiting for first consumer to be created before binding
```

Now create the consumer:

```bash
kubectl apply -f pod-both-volumes.yaml
kubectl get pv
```

A second PV appears — `pvc-<uid>`, reclaim policy **`Delete`**, copied from the class. Look at what the provisioner wrote into it:

```bash
kubectl get pv -o jsonpath='{range .items[?(@.spec.claimRef.name=="dynamic-claim")]}{.spec.nodeAffinity}{"\n"}{end}'
# {"required":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"kubernetes.io/hostname","operator":"In","values":["worker-1"]}]}]}}

kubectl get pv manual-pv001 -o jsonpath='{.spec.nodeAffinity}'
# (empty)
```

**That pair of outputs is the whole reason the Pod is pinned.** The dynamic PV tells the scheduler which node holds it. The manual `hostPath` PV tells it nothing.

## Proving persistence

```bash
kubectl exec ubuntu -- sh -c 'echo hello > /manual/test; echo hello > /dynamic/test'
kubectl delete pod ubuntu
kubectl apply -f pod-both-volumes.yaml
kubectl exec ubuntu -- cat /manual/test /dynamic/test
# hello
# hello
```

And on the node itself:

```bash
ssh worker-1 ls /var/lib/rancher/k3s/storage/
# manual-pv001
# pvc-<uid>_default_dynamic-claim
```

### What the nodeSelector is protecting against

Remove the `nodeSelector`, delete everything, and run a Pod that mounts **only** `manual-claim`. If it lands on `worker-2`, `DirectoryOrCreate` makes a fresh, **empty** directory there — and `cat /manual/test` fails even though the file is sitting safely on `worker-1`. Persistent does not mean portable.

Then try `nodeName: worker-1` instead of `nodeSelector` with a **new** dynamic claim. The Pod is placed, but the claim never binds: `nodeName` bypasses the scheduler, and with `WaitForFirstConsumer` the scheduler is what triggers provisioning.

## Reclaim policies, side by side

```bash
kubectl delete pod ubuntu
kubectl delete pvc manual-claim dynamic-claim
kubectl get pv
```

```
NAME           CAPACITY   RECLAIM POLICY   STATUS     CLAIM
manual-pv001   10Gi       Retain           Released   default/manual-claim
```

**One deletion, two outcomes.**

- The **dynamic** PV is gone — object *and* directory, because it inherited **`Delete`** from the StorageClass.
- The **manual** PV is **`Released`** — its data still on `worker-1`'s disk, because a manually created PV defaults to **`Retain`**.

A `Released` PV will **not** bind to a new claim. Try it:

```bash
kubectl apply -f static-pv.yaml          # recreates only the claim; the PV exists
kubectl get pvc manual-claim             # Pending — the PV is Released, not Available
```

Reclaiming it is a manual job: delete the PV, clean the data, then recreate the PV.

```bash
kubectl delete -f static-pv.yaml
ssh worker-1 sudo rm -rf /var/lib/rancher/k3s/storage/manual-pv001
```

## Cleaning up

```bash
kubectl delete -f pod-both-volumes.yaml -f dynamic-pvc.yaml -f static-pv.yaml -f emptydir-memory.yaml --ignore-not-found
```
