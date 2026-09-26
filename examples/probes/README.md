# Probes

Companion manifest for [`14-probes`](../../notes/04-kubernetes-fundamentals/14-probes.md).

| File | What it is |
|---|---|
| [`probe-demo.yaml`](probe-demo.yaml) | All three probes on one container, using the course's chaos-testing image so the normally-invisible probe lifecycle shows up in the Pod's own logs |

The image is [`spurin/readiness-liveness-startup-probe-api`](https://github.com/spurin/readiness-liveness-startup-probe-api). It logs every probe request and takes environment variables that inject delays and failures, which is what makes this worth running rather than reading.

## Watch the whole thing in one pane

```bash
kubectl apply -f probe-demo.yaml
watch 'kubectl describe pod/probe-demo | sed 0,/Events:/d | tail -20; echo; \
       kubectl logs pod/probe-demo --tail=15; echo; kubectl get pod/probe-demo'
```

## What you should see, in order

| Time | What happens |
|---|---|
| **0–30s** | `/startup` returns 500, so the startup probe fails. `READY 0/1`. **No readiness or liveness events at all** — they are not failing, they are not running |
| **~30s** | `/startup` succeeds once. The startup probe stops **forever**; liveness and readiness begin, and their `initialDelaySeconds` starts counting now |
| **~40s** | `/ready` starts succeeding. `READY` goes `0/1` → `1/1` and the Pod would now receive Service traffic |
| **~50s+** | `/healthz` fails permanently after 10 calls. Liveness crosses `failureThreshold` and you get `Killing — Container probe-demo failed liveness probe, will be restarted`. `RESTARTS` increments |

The detail worth catching in that last step: the **readiness probe kept succeeding the whole time** the liveness probe was failing. They are scheduled independently, and only one of them restarts anything.

## Two experiments

**Delete the `startupProbe` and re-apply.** The liveness probe now runs from the start, kills the container before `STARTUP_DELAY` has elapsed, and you get a boot loop that looks exactly like a crash but is really a misconfigured timeout. That is the failure a startup probe exists to prevent — and the one that bites slow-starting JVM apps hardest.

**Raise `HEALTHZ_PERMANENT_FAILURE_THRESHOLD` and leave `HEALTHZ_CHAOS_FREQUENCY: "3"`.** Now `/healthz` fails every third call but never permanently. `failureThreshold: 3` requires three *consecutive* failures, so the container is never restarted — a good demonstration of why the threshold exists and why setting it to 1 is usually a mistake.

## Budgets in this file

| Probe | `failureThreshold` × `periodSeconds` | Budget |
|---|---|---|
| `startupProbe` | 8 × 5 | **40s** — comfortably above the 30s `STARTUP_DELAY` |
| `livenessProbe` | 3 × 5 | 15s of tolerance once running |
| `readinessProbe` | 3 × 5 | 15s before traffic is withdrawn |

```bash
kubectl delete -f probe-demo.yaml
```
