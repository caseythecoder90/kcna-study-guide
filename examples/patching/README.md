# Patching

Companion files for [`07-set-image-and-patch`](../../notes/04-kubernetes-fundamentals/07-set-image-and-patch.md). The point of the set is to run the **same intention** through all three patch types and watch them diverge.

| File | What it is |
|---|---|
| [`web-deployment.yaml`](web-deployment.yaml) | A two-container Deployment (nginx + a busybox sidecar) — the target |
| [`strategic-image.yaml`](strategic-image.yaml) | Strategic merge patch: update nginx, keep the sidecar |
| [`merge-image.yaml`](merge-image.yaml) | **The same body** as a JSON merge patch — and it deletes the sidecar |
| [`json-image.yaml`](json-image.yaml) | JSON Patch (RFC 6902) with a `test` guard, written as YAML |
| [`json-add-container.yaml`](json-add-container.yaml) | JSON Patch appending a container with `path: .../containers/-` |

## The experiment

```bash
kubectl apply -f web-deployment.yaml
kubectl get deploy web -o jsonpath='{.spec.template.spec.containers[*].name}{"\n"}'   # nginx sidecar

# 1. strategic merge — the default. Merges the containers list BY NAME.
kubectl patch deployment web --patch-file=strategic-image.yaml
kubectl get deploy web -o jsonpath='{range .spec.template.spec.containers[*]}{.name}{"="}{.image}{"\n"}{end}'
# nginx=nginx:1.27 · sidecar=busybox   <- both still there

# reset
kubectl delete -f web-deployment.yaml ; kubectl apply -f web-deployment.yaml

# 2. THE SAME BODY as a JSON merge patch. Arrays are values, so the list is replaced.
kubectl patch deployment web --type=merge --patch-file=merge-image.yaml
kubectl get deploy web -o jsonpath='{range .spec.template.spec.containers[*]}{.name}{"="}{.image}{"\n"}{end}'
# nginx=nginx:1.27                     <- the sidecar is GONE

# reset, then 3. JSON Patch — positional, atomic, with a test guard
kubectl delete -f web-deployment.yaml ; kubectl apply -f web-deployment.yaml
kubectl patch deployment web --type=json --patch-file=json-image.yaml

# 4. append a container
kubectl patch deployment web --type=json --patch-file=json-add-container.yaml
kubectl get deploy web -o jsonpath='{.spec.template.spec.containers[*].name}{"\n"}'   # nginx sidecar extra

kubectl delete -f web-deployment.yaml
```

## You do not need `yq`

Every file here is YAML, including the `--type=json` ones. `kubectl patch` converts its patch input from YAML to JSON **before** it looks at `--type`, so a JSON 6902 patch can be written as a readable YAML list. That removes the reason to shell-quote nested JSON on one line.

`yq` is still handy when a file is not an option and you want the one-liner for a script:

```bash
cat json-add-container.yaml | yq -o=json -I=0
```

## Watch the rollout while you patch

```bash
kubectl get rs -w        # a new ReplicaSet per spec.template change
kubectl rollout history deployment/web
```

Every patch above touches `spec.template`, so every one creates a new ReplicaSet and a new revision. Patching `spec.replicas` instead would scale without adding a revision:

```bash
kubectl patch deployment web --subresource=scale --type=merge -p '{"spec":{"replicas":4}}'
kubectl rollout history deployment/web    # unchanged
```
