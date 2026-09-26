# Secrets

Companion manifest for [`11-secrets`](../../notes/04-kubernetes-fundamentals/11-secrets.md).

| File | What it is |
|---|---|
| [`secret-demo.yaml`](secret-demo.yaml) | An `Opaque` Secret using both `data` and `stringData`, consumed three ways by one Pod |

```bash
kubectl apply -f secret-demo.yaml
kubectl get secrets                  # TYPE column; DATA = number of keys, not bytes
kubectl logs pod/secret-consumer
```

## The point: base64 is not encryption

```bash
kubectl get secret db-creds -o yaml                                        # base64, not ciphertext
kubectl get secret db-creds -o jsonpath='{.data.password}' | base64 -d     # supersecret
kubectl describe secret db-creds                                           # redacted HERE, but not above
```

`describe` hiding the value is a courtesy, not a control. Anyone with `get` on Secrets reads them; anyone with **`list` or `watch` reads every Secret in the namespace**; and anyone who can create a Pod can mount one and print it. What actually protects a Secret is **encryption at rest** plus **least-privilege RBAC**.

## `stringData` is write-only

The manifest sets `username` under `stringData` and `password` under `data`. Read the object back:

```bash
kubectl get secret db-creds -o yaml
```

Both appear under `data`, base64-encoded. `stringData` exists so you can *write* plaintext; it never comes back. On a key collision, `stringData` wins.

## Things the logs show

- **`envFrom` skips `connection.properties`** — a `.` is not a valid shell variable name, exactly as with a ConfigMap.
- **The volume is `tmpfs`.** The kubelet keeps mounted Secret data in RAM so it never touches durable storage, and drops it when the Pod goes. The `mount | grep` line in the container proves it.
- **`defaultMode: 0400`** is worth copying — tighter than the ConfigMap default.

## A TLS Secret, for comparison

```bash
openssl req -x509 -nodes -newkey rsa:2048 -keyout tls.key -out tls.crt -days 365 -subj "/CN=example.com"
kubectl create secret tls my-site-tls --cert=tls.crt --key=tls.key
kubectl get secret my-site-tls                                          # TYPE kubernetes.io/tls, DATA 2
kubectl get secret my-site-tls -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout -subject -dates
kubectl delete secret my-site-tls && rm -f tls.crt tls.key
```

The type is a convention: the API server checks that `tls.crt` and `tls.key` exist, and every Ingress controller knows to look for exactly those keys. It is also the format **cert-manager** writes into.

```bash
kubectl delete -f secret-demo.yaml
```
