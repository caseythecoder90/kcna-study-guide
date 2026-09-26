# ConfigMaps

Companion files for [`10-configmaps`](../../notes/04-kubernetes-fundamentals/10-configmaps.md).

| File | What it is |
|---|---|
| [`configmap-demo.yaml`](configmap-demo.yaml) | One ConfigMap consumed **all four ways** by one Pod — `configMapKeyRef`, `envFrom`, a volume mount, and a `subPath` mount |
| [`app.properties`](app.properties) | A three-line properties file, for comparing `--from-file` against `--from-env-file` |

```bash
kubectl apply -f configmap-demo.yaml
kubectl logs pod/config-consumer
```

The log output walks through all four methods and shows one thing worth seeing: the `app.properties` key **does not** become an environment variable under `envFrom`, because a `.` is not a valid shell variable name. Kubernetes skips such keys and records an event rather than failing.

## The same file, two flags

```bash
kubectl create configmap from-file     --from-file=app.properties     --dry-run=client -o yaml
kubectl create configmap from-env-file --from-env-file=app.properties --dry-run=client -o yaml
```

The first gives **one key** called `app.properties` holding all three lines. The second gives **three keys** — `colour`, `size`, `retries` — and the filename disappears. Same input file, completely different object.

Use `--from-file` when the container wants a config *file*; `--from-env-file` when it wants environment *variables*.

## Proving the update rule

```bash
kubectl patch configmap demo --type=merge -p '{"data":{"colour":"green"}}'

kubectl exec config-consumer -- cat /etc/config/colour           # green, within a kubelet sync period
kubectl exec config-consumer -- printenv COLOUR                  # still blue — env vars never update
kubectl exec config-consumer -- cat /etc/single/app.properties   # still the old text — subPath never updates
```

Three consumption methods, three different behaviours, from one edit. This is the table in the chapter, made real.

Note that even the file that *does* update only helps if the application re-reads it — most parse config once at startup, which is what `kubectl rollout restart` is for.

```bash
kubectl delete -f configmap-demo.yaml
```
