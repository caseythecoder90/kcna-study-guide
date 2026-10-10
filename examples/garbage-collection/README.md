# Garbage collection

Companion lab for [`05-19 Garbage collection`](../../notes/05-kubernetes-deep-dive/19-garbage-collection.md).

| File | What it does |
|---|---|
| [`job-ttl.yaml`](job-ttl.yaml) | A Job with `ttlSecondsAfterFinished: 60` — removed by the TTL-after-finished controller a minute after it completes |

## Owner references

```bash
kubectl create deployment web --image=nginx --replicas=2
kubectl get rs -l app=web -o jsonpath='{.items[0].metadata.ownerReferences}{"\n"}'     # kind Deployment, controller true
kubectl get pods -l app=web -o jsonpath='{.items[0].metadata.ownerReferences}{"\n"}'   # kind ReplicaSet
```

## The three propagation policies

```bash
# Orphan: the Deployment goes, the ReplicaSet and Pods keep running with no owner
kubectl delete deployment web --cascade=orphan
kubectl get deploy,rs,pods -l app=web
kubectl get rs -l app=web -o jsonpath='{.items[0].metadata.ownerReferences}{"\n"}'     # empty

# Re-create the Deployment: it ADOPTS the orphaned ReplicaSet -- no Pods restart
kubectl create deployment web --image=nginx --replicas=2
kubectl get pods -l app=web                    # same Pod names and AGE as before

# Foreground: watch the Deployment stay visible while its dependents go first
kubectl delete deployment web --cascade=foreground --wait=false
kubectl get deploy web -o jsonpath='{.metadata.finalizers}{" "}{.metadata.deletionTimestamp}{"\n"}'   # ["foregroundDeletion"] <time>

# Background (the default) -- for comparison
kubectl create deployment web2 --image=nginx
kubectl delete deployment web2                 # returns at once; RS and Pods vanish a moment later
```

## A self-cleaning Job

```bash
kubectl apply -f job-ttl.yaml
kubectl get job,pods -l job-name=hello-ttl -w  # Complete after ~5s, gone ~60s later
```

## Node-level cleanup (read-only)

```bash
# The kubelet's image GC thresholds, from the live kubelet config
kubectl get --raw "/api/v1/nodes/<node>/proxy/configz" | python -m json.tool | grep -i -E "imageGC|imageMinimumGCAge|imageMaximumGCAge"
```
