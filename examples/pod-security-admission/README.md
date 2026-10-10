# Pod Security Admission

Companion manifests for [`05-16 Pod Security Admission`](../../notes/05-kubernetes-deep-dive/16-pod-security-admission.md). PSA is built in (v1.25+) — the only setup is labelling namespaces.

| File | What it does |
|---|---|
| [`namespaces.yaml`](namespaces.yaml) | Four namespaces: unlabelled, baseline, restricted, and enforce-baseline + warn/audit-restricted |
| [`insecure-pod.yaml`](insecure-pod.yaml) | Root, hostNetwork, hostPID, privileged — fails baseline |
| [`plain-pod.yaml`](plain-pod.yaml) | An ordinary nginx Pod — passes baseline, fails restricted |
| [`restricted-pods.yaml`](restricted-pods.yaml) | Two restricted-compliant Pods — only one of them actually starts |
| [`plain-deployment.yaml`](plain-deployment.yaml) | Why `warn` is paired with `enforce` at the same level |

```bash
kubectl apply -f namespaces.yaml
kubectl get ns -l pod-security.kubernetes.io/enforce --show-labels
```

## Same Pod, two namespaces

```bash
kubectl apply -n psa-unrestricted -f insecure-pod.yaml      # pod/insecure-pod created
kubectl apply -n psa-baseline     -f insecure-pod.yaml
# Error from server (Forbidden): ... violates PodSecurity "baseline:latest":
#   host namespaces (hostNetwork=true, hostPID=true), privileged (...)
```

`runAsUser: 0` is not in the list — **baseline allows root**.

## Different levels per mode are checked independently

```bash
kubectl apply -n psa-warn-audit -f plain-pod.yaml
# Warning: would violate PodSecurity "restricted:latest": allowPrivilegeEscalation != false (...), unrestricted
#   capabilities (...), runAsNonRoot != true (...), seccompProfile (...)
# pod/plain-nginx created

kubectl apply -n psa-warn-audit -f insecure-pod.yaml
# Error from server (Forbidden): ... violates PodSecurity "baseline:latest": ...
```

**enforce=baseline is the floor; warn/audit=restricted is the report.** The plain Pod passes baseline, so it is created — with a warning. The insecure Pod fails baseline, so it is rejected — and no warning is printed, because a rejected request never gets warnings added.

## warn at the same level as enforce

A direct Pod gets no benefit from it:

```bash
kubectl apply -n psa-restricted -f plain-pod.yaml
# Error from server (Forbidden): ... violates PodSecurity "restricted:latest": ...    (no separate warning)
```

A Deployment does. Remove the warn labels to see the difference:

```bash
kubectl label ns psa-restricted pod-security.kubernetes.io/warn- pod-security.kubernetes.io/warn-version-
kubectl apply -n psa-restricted -f plain-deployment.yaml
# deployment.apps/plain-web created          <- accepted SILENTLY
kubectl get deploy -n psa-restricted plain-web        # READY 0/2
kubectl describe rs -n psa-restricted -l app=plain-web | grep -A2 FailedCreate
```

Put the warn label back and reapply:

```bash
kubectl delete -n psa-restricted -f plain-deployment.yaml
kubectl label ns psa-restricted pod-security.kubernetes.io/warn=restricted pod-security.kubernetes.io/warn-version=latest
kubectl apply -n psa-restricted -f plain-deployment.yaml
# Warning: would violate PodSecurity "restricted:latest": ...
# deployment.apps/plain-web created          <- same outcome, but now you are TOLD
```

`enforce` never runs against workload resources, only against the Pods they create. `warn` checks both — that is its entire value when the levels match.

## Admitted is not the same as running

```bash
kubectl apply -n psa-restricted -f restricted-pods.yaml
kubectl get pods -n psa-restricted
# nginx-spec-only      0/1   CreateContainerConfigError
# nginx-unprivileged   1/1   Running
kubectl describe pod -n psa-restricted nginx-spec-only | grep -i "runAsNonRoot"
# Error: container has runAsNonRoot and image will run as root
```

Both passed admission — PSA reads the **spec**. The kubelet then checked the **image**: stock nginx runs as root, so `runAsNonRoot: true` stopped it at start-up. `nginx-unprivileged` runs as UID 101 on port 8080 and starts normally.

## Preview before enforcing

```bash
kubectl label --dry-run=server --overwrite ns psa-unrestricted pod-security.kubernetes.io/enforce=baseline
# Warning: existing pods in namespace "psa-unrestricted" violate the new PodSecurity enforce level "baseline:latest"
# Warning: insecure-pod: host namespaces, privileged
```

Nothing is saved — and even a real `enforce` label would not evict the running Pod, only block new ones.

## Cleaning up

```bash
kubectl delete -f namespaces.yaml          # deletes everything inside them too
```
