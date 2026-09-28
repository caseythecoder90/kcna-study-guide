# The Kubernetes API

Companion files for [`05-01 The Kubernetes API`](../../notes/05-kubernetes-deep-dive/01-kubernetes-api.md).

| File | What it is |
|---|---|
| [`widget-crd.yaml`](widget-crd.yaml) | A CustomResourceDefinition that adds a new kind to the API server |
| [`widget-instance.yaml`](widget-instance.yaml) | An instance of that kind |

## Watch the API server grow a new path

```bash
kubectl apply -f widget-crd.yaml

kubectl api-resources | grep widget        # it is in the list now
kubectl api-versions | grep example.com    # a new group/version
kubectl explain widget.spec                # the CRD's own schema, read back
```

```bash
kubectl proxy &
curl -s localhost:8001/apis/example.com/v1/widgets | head
```

That path did not exist a minute ago. Installing a CRD is a **write to the API server that changes what the API server serves.**

## It behaves like a built-in

```bash
kubectl apply -f widget-instance.yaml
kubectl get widgets                        # or `kubectl get wid`, via the CRD's shortName
kubectl get widget my-widget -o yaml       # stored in etcd like anything else
kubectl describe widget my-widget
kubectl auth can-i list widgets            # RBAC covers it
kubectl get widget my-widget -o jsonpath='{.spec.size}{"\n"}'   # 10 — the schema default filled it in
```

The `additionalPrinterColumns` in the CRD are why `kubectl get widgets` has Colour and Size columns, exactly as built-in kinds have their own.

## The schema really is enforced

```bash
kubectl apply -f - <<'YAML'
apiVersion: example.com/v1
kind: Widget
metadata: {name: bad-widget}
spec: {colour: purple}
YAML
```

```
The Widget "bad-widget" is invalid: spec.colour: Unsupported value: "purple":
supported values: "red", "green", "blue"
```

Authentication passed, authorization passed, admission passed — and it still failed, at the **validation** step that comes after all three (stage 4 in the chapter's diagram).

## The point: a CRD adds the noun, not the verb

Creating that Widget produced **no Pod, no Deployment, nothing**. The object was validated and stored, and that is the entirety of what a CRD promises.

What turns it into infrastructure is an **operator** — a controller watching this kind and reconciling reality toward the spec. That is the same control loop the built-in controllers run in chapter 04-01, applied to a kind you invented. Every CNCF project that ships a `ServiceMonitor`, a `Certificate` or an `Application` works exactly this way.

## Seeing the requests underneath

```bash
kubectl get widgets --v=6    # the URL and status
kubectl get widgets --v=8    # the full request and response bodies
```

`--v=8` is the trick worth keeping: run the kubectl command that does what you want, read the JSON it actually sent, and use that as the starting payload for your own client. It is smaller and clearer than the OpenAPI schema because it is the minimal object rather than every possible field.

```bash
kubectl delete -f widget-instance.yaml -f widget-crd.yaml
```

Deleting the CRD deletes every Widget with it — ownership cascades, the same rule as chapter 04-09.
