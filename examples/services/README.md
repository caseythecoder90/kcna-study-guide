# Services

Companion manifest for [`08-services`](../../notes/04-kubernetes-fundamentals/08-services.md).

| File | What it shows |
|---|---|
| [`all-service-types.yaml`](all-service-types.yaml) | One Deployment exposed **five ways at once** — ClusterIP, NodePort, LoadBalancer, headless and ExternalName — so a single `kubectl get service` shows every shape side by side |

```bash
kubectl apply -f all-service-types.yaml
kubectl get service
kubectl get endpoints
```

What to look at in that output:

- **`nginx-headless` has `None` in the CLUSTER-IP column**, not an address. It is still `type: ClusterIP` — headless is a variant, not a fifth type.
- **`nginx-external` has no CLUSTER-IP and no PORT(S)** at all. There is nothing to proxy; it is a DNS alias.
- **`nginx-loadbalancer` sits at `<pending>`** on any cluster without a cloud provider or MetalLB. That is correct behaviour — Kubernetes ships no load balancer.
- **Every selector-based Service lists the same three Pod IPs** in `kubectl get endpoints`, because they all select the same Pods. The Service never knew about the Deployment.

## The DNS experiment

The whole point of the file is this comparison, run from a throwaway Pod on the Pod network:

```bash
kubectl run -it --rm curl --image=curlimages/curl --restart=Never -- sh
```

```sh
cat /etc/resolv.conf          # the search list that makes short names work
nslookup nginx-clusterip      # ONE answer  — the virtual IP
nslookup nginx-headless       # THREE answers — the Pod IPs themselves
nslookup nginx-external       # a CNAME to nginx-clusterip
curl nginx-clusterip          # repeat a few times
curl nginx-headless           # repeat a few times
exit
```

Both `curl` loops reach different Pods, and that is the trap. With **ClusterIP** the balancing is kube-proxy's, below the client, per connection. With **headless** it is the resolver picking from a multi-answer DNS response — so a client that resolves once and holds the connection pins itself to a single Pod.

## Repointing an ExternalName

```bash
kubectl patch service nginx-external --type=merge \
  -p '{"spec":{"externalName":"kubernetes.default.svc.cluster.local"}}'
kubectl run -it --rm curl --image=curlimages/curl --restart=Never -- nslookup nginx-external
```

The CNAME changes and every client following that name moves with it, without a single client-side edit. That is the indirection ExternalName buys.

```bash
kubectl delete -f all-service-types.yaml
```
