# Namespaces

Companion manifest for [`04-namespaces`](../../notes/04-kubernetes-fundamentals/04-namespaces.md).

| File | What it shows |
|---|---|
| [`team-a-governed.yaml`](team-a-governed.yaml) | A Namespace plus a **ResourceQuota** (the total for all objects) and a **LimitRange** (the rule each container obeys, and the defaults injected when one says nothing), in one multi-document file |

```bash
kubectl apply -f team-a-governed.yaml
kubectl describe namespace team-a
```

The point of having both in one file is that they fail differently. A Pod that asks for more CPU than the per-container `max` is rejected by the **LimitRange**. Twelve Pods that are each individually legal but together exceed `requests.cpu: "4"` are rejected by the **ResourceQuota**. Each versus all — the file's comments walk through both, plus the case where a Pod declares no resources at all and the LimitRange quietly supplies them.

Clean up with `kubectl delete namespace team-a`, which removes every object inside it.
