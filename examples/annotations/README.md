# Annotations

Companion manifest for [`13-annotations`](../../notes/04-kubernetes-fundamentals/13-annotations.md).

| File | What it is |
|---|---|
| [`annotated-deployment.yaml`](annotated-deployment.yaml) | A Deployment with annotations in **both** `metadata` blocks, so the difference in blast radius can be demonstrated rather than taken on trust |

```bash
kubectl apply -f annotated-deployment.yaml
kubectl get rs                                 # ONE ReplicaSet
kubectl rollout history deployment/web         # revision 1
```

## The experiment worth running

**Annotate the Deployment — nothing restarts:**

```bash
kubectl annotate deployment/web company.org/ticket=OPS-9999 --overwrite
kubectl get rs                                 # still ONE
kubectl rollout history deployment/web         # still revision 1
kubectl get pods                               # same Pods, AGE still climbing
```

**Annotate the pod template — a full rolling update:**

```bash
kubectl patch deployment web -p '{"spec":{"template":{"metadata":{"annotations":{"company.org/note":"changed"}}}}}'
kubectl get rs                                 # TWO ReplicaSets
kubectl rollout history deployment/web         # revision 2
kubectl get pods                               # brand new Pods
```

One character of indentation apart in the manifest, and one of them replaced every Pod in production. `.spec.template` changed, so the `pod-template-hash` changed, so a new ReplicaSet was created — chapter 05's rule with no exception.

**The same mechanism, on purpose:**

```bash
kubectl rollout restart deployment/web
kubectl get deploy web -o jsonpath='{.spec.template.metadata.annotations}' | python -m json.tool
```

`rollout restart` stamps `kubectl.kubernetes.io/restartedAt` **into the template**. That is precisely how it forces a rollout without changing the image.

## Annotations are not selectable

```bash
kubectl get pods -l app=web                    # works — app is a LABEL
kubectl get pods -o json | jq -r '.items[] | select(.metadata.annotations."company.org/note") | .metadata.name'
```

There is no `--annotation-selector` and no `--show-annotations`. Filtering by annotation means fetching everything and filtering client-side. If you find yourself wanting to select on one, it should have been a label.

## Things the manifest demonstrates in passing

- **Values must be strings.** `company.org/max-surge-note: "25"` is quoted deliberately — an unquoted `25` would be rejected.
- **No character restrictions.** `company.org/contacts` holds a JSON document, which a label could never do (63 characters, restricted charset).
- **Controller hints belong in the template.** `prometheus.io/scrape` sits with the Pod because that is the object Prometheus discovers.

```bash
kubectl delete -f annotated-deployment.yaml
```
