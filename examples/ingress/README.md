# Ingress

Companion manifests for [`05-11 Ingress`](../../notes/05-kubernetes-deep-dive/11-ingress.md).

| File | What it does |
|---|---|
| [`backends.yaml`](backends.yaml) | Three `spurin/nginx-debug` Pods and ClusterIP Services — each response names the Pod and the URL it received |
| [`ingress-http.yaml`](ingress-http.yaml) | One host, four paths — three `Prefix` and one `Exact` |
| [`ingress-tls.yaml`](ingress-tls.yaml) | The same routing with TLS terminated at the controller, plus the redirect annotations |

## 1. Install a controller

The Ingress API exists in every cluster; a controller to act on it usually does not. The lecture uses F5 NGINX:

```bash
helm repo add nginx-stable https://helm.nginx.com/stable
helm repo update
helm install nginx-ingress nginx-stable/nginx-ingress --namespace nginx-ingress --create-namespace

kubectl -n nginx-ingress get service          # LoadBalancer on 80 and 443 -- note the EXTERNAL-IP
kubectl get ingressclasses                    # nginx   nginx.org/ingress-controller
```

On k3s, Traefik is installed by default and also listens on ports 80 and 443. If the F5 Service's `EXTERNAL-IP` stays `<pending>`, Traefik is probably holding those ports — start the k3s server with `--disable=traefik`, or keep Traefik and use `ingressClassName: traefik` instead.

Make `nginx` the default class (what the lecture's `kubectl edit` did):

```bash
kubectl annotate ingressclass nginx ingressclass.kubernetes.io/is-default-class=true
```

Set the address once for the commands below:

```bash
IP=$(kubectl -n nginx-ingress get svc nginx-ingress-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo $IP
```

## 2. Route by path

```bash
kubectl apply -f backends.yaml -f ingress-http.yaml
kubectl get ingress                            # CLASS nginx, HOSTS myingress-app.local, ADDRESS $IP
kubectl describe ingress myingress-app         # the rules as the API stored them
```

```bash
curl -s --resolve "myingress-app.local:80:$IP" http://myingress-app.local/        | grep -E "Hostname|URL"
curl -s --resolve "myingress-app.local:80:$IP" http://myingress-app.local/api     | grep -E "Hostname|URL"
curl -s --resolve "myingress-app.local:80:$IP" http://myingress-app.local/admin   | grep -E "Hostname|URL"
```

```
Hostname: nginx-frontend   URL: /
Hostname: nginx-api        URL: /api
Hostname: nginx-admin      URL: /admin
```

Same IP, same port, three Pods. Note the backend receives the **full path** (`/api`, not `/`) — Ingress does not strip it.

**The Host header is the whole trick.** Same request, wrong host:

```bash
curl -s -o /dev/null -w "%{http_code}\n" -H "Host: something-else.local" http://$IP/api   # 404
curl -s -H "Host: myingress-app.local" http://$IP/api | grep Hostname                     # nginx-api
```

## 3. pathType, tested

Predict each answer before running it. The Kubernetes-spec answer and the F5 NGINX answer differ on one of them.

```bash
for p in /api /api/ /api/v1/users /API /apiary /cart /healthz /healthz/ /healthz/x; do
  printf "%-16s -> " "$p"
  curl -s --resolve "myingress-app.local:80:$IP" "http://myingress-app.local$p" | grep -o "Hostname: [a-z-]*" || echo "(no backend)"
done
```

| Request | Spec says | Why |
|---|---|---|
| `/api`, `/api/`, `/api/v1/users` | nginx-api | `/api` is the first element; trailing slash ignored; subpaths match |
| `/API` | nginx-frontend | Case-sensitive — falls through to `/` |
| **`/apiary`** | **nginx-frontend** | **Element-wise: `apiary` is not `api`** |
| `/cart` | nginx-frontend | `/` is the catch-all |
| `/healthz` | nginx-admin | Exact match |
| `/healthz/`, `/healthz/x` | nginx-frontend | Exact does not match a trailing slash or subpaths |

**On F5 NGINX, `/apiary` returns `nginx-api`.** The controller writes `Prefix /api` as an NGINX `location /api`, which is a plain string prefix. The spec says otherwise, and the exam wants the spec — but this is the behaviour you would actually see on this controller, and it is why edge cases are worth testing.

## 4. TLS

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout myingress-app.local.key -out myingress-app.local.crt \
  -subj "/CN=myingress-app.local" \
  -addext "subjectAltName=DNS:myingress-app.local"

openssl x509 -in myingress-app.local.crt -noout -subject -ext subjectAltName -dates   # check the SAN is there

kubectl create secret tls myingress-app-tls --cert=myingress-app.local.crt --key=myingress-app.local.key
kubectl get secret myingress-app-tls -o jsonpath='{.type}'                            # kubernetes.io/tls

kubectl apply -f ingress-tls.yaml
```

**HTTP now redirects:**

```bash
curl -si --resolve "myingress-app.local:80:$IP" http://myingress-app.local/api | head -3
# HTTP/1.1 308 Permanent Redirect
# Location: https://myingress-app.local/api
```

**HTTPS with a self-signed certificate**, three ways:

```bash
# 1. Normal verification FAILS -- nothing trusts your homemade CA
curl -s --resolve "myingress-app.local:443:$IP" https://myingress-app.local/api
# curl: (60) SSL certificate problem: self-signed certificate

# 2. -k skips verification: encrypted, but the server is NOT authenticated
curl -sk --resolve "myingress-app.local:443:$IP" https://myingress-app.local/api | grep Hostname

# 3. --cacert trusts exactly this certificate: verification passes, which also proves the SAN is right
curl -s --cacert myingress-app.local.crt --resolve "myingress-app.local:443:$IP" https://myingress-app.local/api | grep Hostname

# -L follows the redirect from http:// all the way to the page
curl -sL --cacert myingress-app.local.crt --resolve "myingress-app.local:80:$IP" \
  --resolve "myingress-app.local:443:$IP" http://myingress-app.local/api | grep Hostname
```

See the certificate the controller presents — chosen by **SNI**, the hostname sent in the TLS handshake:

```bash
openssl s_client -connect $IP:443 -servername myingress-app.local </dev/null 2>/dev/null \
  | openssl x509 -noout -subject -ext subjectAltName
```

Drop `-servername` and no hostname is sent, so the controller cannot pick `myingress-app-tls` by name — what happens then (a default certificate, or a refused handshake) is controller-specific. Either way the difference is SNI made visible.

The response still shows `IP Address: ...:80` — **TLS ended at the controller**, and the Pod received plain HTTP on port 80.

## Cleaning up

```bash
kubectl delete -f ingress-tls.yaml -f backends.yaml --ignore-not-found
kubectl delete secret myingress-app-tls
helm uninstall nginx-ingress -n nginx-ingress
rm -f myingress-app.local.key myingress-app.local.crt
```
