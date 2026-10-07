# Network policies

Companion manifests for [`05-10 Network policies`](../../notes/05-kubernetes-deep-dive/10-network-policies.md).

| File | What it does |
|---|---|
| [`lab.yaml`](lab.yaml) | nginx, an allowed `curl` Pod, an identical `intruder` Pod, and the lecture's policy with its port corrected |
| [`default-deny.yaml`](default-deny.yaml) | Deny-all for the namespace, the DNS egress exception it needs, and the egress allow the curl Pod then needs |

**First, check your CNI enforces policies.** k3s does, through its embedded controller. On plain Flannel every step below "works" — the policies are accepted and ignored.

## Open by default

Apply only the Pods and Service first (delete the NetworkPolicy section, or apply and then `kubectl delete networkpolicy allow-nginx-access`):

```bash
kubectl exec curl     -- curl -s -m 3 nginx | grep title    # <title>Welcome to nginx!</title>
kubectl exec intruder -- curl -s -m 3 nginx | grep title    # <title>Welcome to nginx!</title>
```

Both succeed. Nothing selects nginx, so nginx is not isolated.

## One policy, two outcomes

```bash
kubectl apply -f lab.yaml
kubectl describe networkpolicy allow-nginx-access
```

```
Spec:
  PodSelector:     run=nginx
  Allowing ingress traffic:
    To Port: 80/TCP
    From:
      PodSelector: run=curl
  Not affecting egress traffic
  Policy Types: Ingress
```

`describe` is the tool the docs recommend for checking how a policy was interpreted — note **"Not affecting egress traffic"**.

```bash
kubectl exec curl     -- curl -s -m 3 nginx | grep title    # still allowed
kubectl exec intruder -- curl -s -m 3 nginx                 # curl: (28) timed out
```

The intruder is identical except for one label. **The block is silent** — packets are dropped, so the client sees a timeout rather than a refusal. That is why `-m 3` is there.

### The lecture's port

Change `port: 80` to `port: 6379`, as on the slide, and reapply:

```bash
kubectl exec curl -- curl -s -m 3 nginx                     # now times out too
```

nginx is still isolated for ingress, and the only allowed traffic is TCP 6379 from `run=curl`. nginx listens on 80, so **nothing is allowed in at all** — `from` and `ports` are ANDed. Change it back.

### The lecture's egress block

The slide's manifest also had an `egress` section, but `policyTypes: [Ingress]` means the Pods are never isolated for egress. Add the slide's egress block without touching `policyTypes`, reapply, and `describe` still says **"Not affecting egress traffic"**. The rules were accepted and do nothing.

## Default deny, then allow

```bash
kubectl apply -f default-deny.yaml
kubectl exec curl -- curl -s -m 3 nginx | grep title        # allowed
kubectl exec curl -- nslookup kubernetes.default            # works: DNS was allowed back
```

Remove the DNS policy and try again:

```bash
kubectl delete networkpolicy allow-dns-egress
kubectl exec curl -- curl -s -m 3 nginx                     # Could not resolve host: nginx
kubectl exec curl -- curl -s -m 3 "$(kubectl get svc nginx -o jsonpath='{.spec.clusterIP}')" | grep title   # allowed
```

**Same Pod, same policy, same destination — but by name it fails and by IP it works.** That is the DNS trap: a default-deny egress policy blocks lookups to kube-dns, and the symptom looks like a broken Service rather than a policy.

Remove `allow-curl-egress-to-nginx` instead and the request fails for the other reason: nginx's ingress allows it, but the curl Pod's own **egress** no longer does. Both ends have to agree.

## Cleaning up

```bash
kubectl delete -f default-deny.yaml -f lab.yaml --ignore-not-found
```
