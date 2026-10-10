# Security contexts

Companion manifests for [`05-15 Security contexts`](../../notes/05-kubernetes-deep-dive/15-security-contexts.md).

| File | What it does |
|---|---|
| [`rootshell-states.yaml`](rootshell-states.yaml) | The lecture's three states: root by default, non-root that escalates, non-root that cannot |
| [`hardened-pod.yaml`](hardened-pod.yaml) | A restricted-compliant Pod using every fence |

> `spurin/rootshell` contains a setuid-root binary that gives any user root. Use it only in a throwaway lab cluster.

## The three states

```bash
kubectl apply -f rootshell-states.yaml

kubectl exec -it state1-root -- id                       # uid=0(root)
```

`/rootshell` starts an interactive root `bash`, so try the other two interactively:

```bash
kubectl exec -it state2-nonroot -- bash
nonpriv@state2-nonroot:/$ id            # uid=1000(nonpriv)
nonpriv@state2-nonroot:/$ /rootshell
root@state2-nonroot:/# id               # uid=0(root) -- escalated
```

```bash
kubectl exec -it state3-no-escalation -- bash
nonpriv@state3-no-escalation:/$ /rootshell
nonpriv@state3-no-escalation:/$ id      # uid=1000(nonpriv) -- refused
```

See the flag that made the difference:

```bash
kubectl exec state2-nonroot       -- grep NoNewPrivs /proc/1/status    # NoNewPrivs: 0
kubectl exec state3-no-escalation -- grep NoNewPrivs /proc/1/status    # NoNewPrivs: 1
```

`allowPrivilegeEscalation: false` is inverted into the kernel's `no_new_privs` flag. With it set, `exec` ignores setuid bits for this process and every child, forever.

## Precedence

```bash
kubectl apply -f https://k8s.io/examples/pods/security/security-context-2.yaml
kubectl exec security-context-demo-2 -- ps aux        # USER 2000 -- the container overrides the Pod's 1000
```

## runAsNonRoot in action

Add `runAsNonRoot: true` to `state1-root` (no `runAsUser`) and reapply:

```bash
kubectl describe pod state1-root | grep -A3 Events
# Error: container has runAsNonRoot and image will run as root
```

The kubelet refused to start it. Now set `runAsUser: 1000` too and it starts — the check passes because the effective UID is no longer 0.

## The hardened Pod

```bash
kubectl apply -f hardened-pod.yaml
kubectl exec hardened -- id                     # uid=1000 gid=1000 groups=1000
kubectl exec hardened -- touch /etc/x           # touch: cannot touch '/etc/x': Read-only file system
kubectl exec hardened -- touch /tmp/x           # works: /tmp is an emptyDir
kubectl exec hardened -- grep -E 'CapEff|NoNewPrivs|Seccomp:' /proc/1/status
# CapEff:     0000000000000000      <- no capabilities at all
# NoNewPrivs: 1
# Seccomp:    2                     <- 2 = filter mode (RuntimeDefault)
```

Swap the image for plain `nginx` and it fails to start: stock nginx needs root to bind port 80 and to write its cache under `/var/cache/nginx`. Hardening works best with images built for it.

## Cleaning up

```bash
kubectl delete -f rootshell-states.yaml -f hardened-pod.yaml
kubectl delete pod security-context-demo-2 --ignore-not-found
```
