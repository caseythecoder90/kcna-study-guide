# StatefulSets

Companion manifest for [`05-09 StatefulSets`](../../notes/05-kubernetes-deep-dive/09-statefulsets.md). Written for **k3s** (`local-path` storage); on another cluster, change or drop `storageClassName`.

| File | What it does |
|---|---|
| [`web-statefulset.yaml`](web-statefulset.yaml) | A headless Service `nginx`, a StatefulSet `web` and a claim template `www` — three different names so each naming formula shows separately |

The lecture called all three objects `nginx`. This one uses the documentation's names, because with three different words you can see which object contributes which part of each name.

## Ordered creation

```bash
kubectl apply -f web-statefulset.yaml
kubectl get pods -w -l app=nginx
```

```
web-0   0/1   Pending             0s
web-0   0/1   ContainerCreating   2s
web-0   1/1   Running             5s
web-1   0/1   Pending             0s     <- only after web-0 is Running and Ready
web-1   1/1   Running             4s
web-2   0/1   Pending             0s
web-2   1/1   Running             4s
```

**One at a time, in ordinal order.** Compare `kubectl create deployment nginx --image=nginx --replicas=3`, whose three Pods appear simultaneously.

## The three names

```bash
kubectl get pods -l app=nginx                  # web-0 web-1 web-2         <statefulset>-<ordinal>
kubectl get pvc                                # www-web-0 www-web-1 ...   <template>-<pod name>
kubectl get pod web-1 --show-labels            # statefulset.kubernetes.io/pod-name=web-1, apps.kubernetes.io/pod-index=1
kubectl get endpoints nginx -o yaml | grep hostname     # hostname: web-0 / web-1 / web-2
```

DNS, from a throwaway Pod:

```bash
kubectl run --rm -i --tty curl --image=curlimages/curl --restart=Never -- sh
nslookup nginx.default.svc.cluster.local       # THREE Pod IPs -- headless, no virtual IP
nslookup web-1.nginx.default.svc.cluster.local # ONE IP: web-1's
curl -s web-1.nginx.default.svc.cluster.local  # always web-1, never a random replica
```

`<pod name>.<service name>.<namespace>.svc.cluster.local` — the Pod name from the StatefulSet, the domain from the Service.

## Sticky identity and sticky storage

Give each Pod a page that says who it is, then destroy one:

```bash
for i in 0 1 2; do kubectl exec web-$i -- sh -c "echo I am web-$i > /usr/share/nginx/html/index.html"; done

kubectl get pod web-1 -o wide                  # note the IP
kubectl delete pod web-1
kubectl get pod web-1 -o wide                  # SAME name, probably a DIFFERENT IP
kubectl exec web-1 -- cat /usr/share/nginx/html/index.html    # I am web-1
```

**The recreated Pod has the old Pod's name, so it claims `www-web-1`, so it has the old Pod's data.** The IP is the one thing that changed — which is why clients address members by DNS name.

## A canary with `partition`

```bash
kubectl patch statefulset web -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":2}}}}'
kubectl set image statefulset/web nginx=nginx:1.29
kubectl get pods -l app=nginx -o custom-columns=NAME:.metadata.name,IMAGE:.spec.containers[0].image
```

```
NAME    IMAGE
web-0   nginx:1.27
web-1   nginx:1.27
web-2   nginx:1.29      <- only ordinal >= 2
```

Delete `web-0` and watch it come back at **1.27**: Pods below the partition are recreated at the previous version, not the new one. Then continue the rollout:

```bash
kubectl patch statefulset web -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":0}}}}'
kubectl rollout status statefulset/web          # web-1, then web-0 -- highest ordinal first
kubectl rollout history statefulset/web
kubectl get controllerrevisions                 # not ReplicaSets
```

## Scaling keeps the claims

```bash
kubectl scale statefulset web --replicas=1      # web-2 terminates, THEN web-1
kubectl get pvc                                 # www-web-1 and www-web-2 are STILL there
kubectl scale statefulset web --replicas=3
kubectl exec web-2 -- cat /usr/share/nginx/html/index.html    # I am web-2 -- the old data
```

**Scaling down does not delete PVCs**, so scaling back up reattaches them with their data. The same holds when the StatefulSet itself is deleted.

## Immutable fields

Change `storage: 1Gi` to `2Gi` in the claim template and `kubectl apply` again — it is rejected, because `volumeClaimTemplates` is immutable. The lecture's workaround deletes and recreates the StatefulSet; the PVCs survive and the new Pods reattach them:

```bash
kubectl delete -f web-statefulset.yaml && kubectl apply -f web-statefulset.yaml
```

## Cleaning up

```bash
kubectl scale statefulset web --replicas=0      # ordered termination: deletion alone guarantees none
kubectl delete -f web-statefulset.yaml
kubectl get pvc --show-labels                   # app=nginx on every claim
kubectl delete pvc -l app=nginx
```

The claims carry `app=nginx` even though the claim template sets no labels: the controller **copies the StatefulSet's `selector.matchLabels` onto every PVC it creates**. That makes the selector a convenient handle for cleaning up the claims that deleting the StatefulSet left behind.
