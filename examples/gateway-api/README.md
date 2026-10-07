# Gateway API

Companion lab for [`05-12 Gateway API`](../../notes/05-kubernetes-deep-dive/12-gateway-api.md). The same backends, hostname pattern and TLS steps as the [Ingress lab](../ingress/), so the two can be compared line for line.

| File | Owner (role) | What it does |
|---|---|---|
| [`01-backends.yaml`](01-backends.yaml) | App team | Four `nginx-debug` Pods + Services, including `nginx-api-v2` |
| [`02-gateway.yaml`](02-gateway.yaml) | Cluster operator | Namespace `gateway-system` and Gateway `edge-gw` with `http` and `https` listeners |
| [`03-httproute.yaml`](03-httproute.yaml) | App team | Path routing, attached to the `https` listener only |
| [`04-redirect.yaml`](04-redirect.yaml) | App team | `RequestRedirect` filter on the `http` listener |
| [`patterns/`](patterns/) | App team | Blue/green, canary, header preview and mirroring — each **replaces** `mygateway-app` |

## 1. CRDs and a controller

Gateway API is not built in. Install the CRDs, then an implementation:

```bash
kubectl get crd | grep gateway.networking.k8s.io        # already there? check the version first

kubectl kustomize "https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=v2.3.0" \
  | kubectl apply -f -
helm install ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric --create-namespace -n nginx-gateway

kubectl get gatewayclass                                # nginx ... ACCEPTED True
kubectl -n nginx-gateway get svc                        # ClusterIP 443 -- the CONTROL plane only
```

On k3s, Traefik also implements Gateway API and may already have installed CRDs; `kubectl get crd` shows what is there. NGINX Gateway Fabric's CRD version must match what it supports.

## 2. TLS material

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout mygateway-app.local.key -out mygateway-app.local.crt \
  -subj "/CN=mygateway-app.local" -addext "subjectAltName=DNS:mygateway-app.local"

kubectl create namespace gateway-system
kubectl -n gateway-system create secret tls mygateway-app-tls \
  --cert=mygateway-app.local.crt --key=mygateway-app.local.key
```

The Secret lives with the **Gateway**, because the Gateway's listener references it — not the application's namespace, as with Ingress.

## 3. A Gateway creates a load balancer

```bash
kubectl apply -f 01-backends.yaml -f 02-gateway.yaml
kubectl -n gateway-system get gateway edge-gw           # ADDRESS ... PROGRAMMED True
kubectl -n gateway-system get deploy,svc                # NEW: an NGINX data plane just for edge-gw
```

**Creating a Gateway object provisioned an NGINX Deployment and a LoadBalancer Service.** That is the "dynamic infrastructure provisioning" in Gateway API's definition — the controller's own Service never handled traffic.

```bash
IP=$(kubectl -n gateway-system get gateway edge-gw -o jsonpath='{.status.addresses[0].value}')
R="--resolve mygateway-app.local:80:$IP --resolve mygateway-app.local:443:$IP"
```

## 4. Routes, redirect, TLS

```bash
kubectl apply -f 03-httproute.yaml -f 04-redirect.yaml
kubectl get httproute
kubectl describe httproute mygateway-app | grep -A3 "Type:"      # Accepted, ResolvedRefs

curl -s  $R --cacert mygateway-app.local.crt https://mygateway-app.local/api | grep Hostname   # nginx-api
curl -si $R http://mygateway-app.local/api | head -3                                             # 301 + Location: https://...
curl -sL $R --cacert mygateway-app.local.crt http://mygateway-app.local/admin | grep Hostname  # follows to https
```

The lecture ran `update-ca-certificates` instead of `--cacert`, which trusts the certificate machine-wide — that is why its `curl https://` needed no flags.

**Break it on purpose** to see why the main route names `sectionName: https`. Delete `sectionName: https` from `03-httproute.yaml`, reapply, and:

```bash
curl -si $R http://mygateway-app.local/api | head -1     # 200, NOT a redirect
```

The main route is now attached to port 80 too, and `/api` is a longer `PathPrefix` than the redirect route's implicit `/`, so it wins. Put `sectionName` back.

**Status when something is wrong.** Change `parentRefs.namespace` to a namespace that does not exist, reapply, and read the route's conditions — `Accepted: False`. Change a `backendRefs` name to a missing Service — `ResolvedRefs: False`, reason `BackendNotFound`. Gateway API tells you *why*; an Ingress would just 404.

## 5. Release patterns

Each file in `patterns/` is a complete `mygateway-app` route, so applying one replaces whatever pattern was there.

```bash
count() { for i in $(seq 1 40); do curl -s $R --cacert mygateway-app.local.crt "$@" | grep -o "Hostname: [a-z0-9-]*"; done | sort | uniq -c; }
```

**Blue/green** — all traffic to one version, switched by editing weights:

```bash
kubectl apply -f patterns/blue-green.yaml
count https://mygateway-app.local/api                     # 40 nginx-api
# edit weights to 0 / 100 and reapply
count https://mygateway-app.local/api                     # 40 nginx-api-v2
```

**Canary** — a small proportion to the new version:

```bash
kubectl apply -f patterns/canary.yaml
count https://mygateway-app.local/api                     # roughly 38 / 2
```

It is a proportion over many requests, not a strict rotation — small samples wobble.

**Preview / A-B** — the request chooses:

```bash
kubectl apply -f patterns/header-preview.yaml
count https://mygateway-app.local/api                         # 40 nginx-api
count -H "X-Preview: true" https://mygateway-app.local/api    # 40 nginx-api-v2
```

**Mirroring** — users only ever see v1:

```bash
kubectl apply -f patterns/mirror.yaml
count https://mygateway-app.local/api                     # 40 nginx-api
kubectl logs nginx-api-v2 --tail=5                        # ...yet v2 received every request
```

v2's access log fills up while no client ever receives its response. That is shadow traffic: real load, zero user impact.

## Cleaning up

```bash
kubectl apply -f 03-httproute.yaml                        # back to plain routing
kubectl delete -f 04-redirect.yaml -f 03-httproute.yaml -f 02-gateway.yaml -f 01-backends.yaml
helm uninstall ngf -n nginx-gateway
rm -f mygateway-app.local.key mygateway-app.local.crt
```

Deleting the Gateway also removes the NGINX data plane and its LoadBalancer the controller provisioned for it.
