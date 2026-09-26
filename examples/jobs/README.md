# Jobs and CronJobs

Companion manifest for [`09-jobs-and-cronjobs`](../../notes/04-kubernetes-fundamentals/09-jobs-and-cronjobs.md).

| File | What it shows |
|---|---|
| [`jobs-and-cronjob.yaml`](jobs-and-cronjob.yaml) | All **three Job patterns** — non-parallel, fixed completion count, work queue — plus a CronJob, in one file |

```bash
kubectl apply -f jobs-and-cronjob.yaml
watch kubectl get jobs,pods
```

## What to watch for

- **`pi-once`** leaves both `completions` and `parallelism` unset, so both default to 1. One Pod, done.
- **`batch-fixed`** has `completions: 6, parallelism: 2`. Six Pods must **succeed**; at most two run at once. You will see three waves of two, and `COMPLETIONS` climb `0/6 → 2/6 → 4/6 → 6/6`. This is the pair the exam contrasts: a **total** versus a **concurrency cap**.
- **`queue-workers`** deliberately omits `completions` and sets `parallelism: 3`. Three Pods start together, and the **first one to succeed completes the whole Job** — the remaining Pods finish but no new ones are created. Note this is *not* the same as `completions: 1`, which would also cap parallelism at 1.
- **`every-minute`** creates a new Job object each minute. Leave it running a few minutes and `kubectl get jobs` still shows only a handful, because `successfulJobsHistoryLimit: 3` prunes the rest.

## The three-level debugging path

```bash
kubectl get cronjobs     # LAST SCHEDULE — did it fire?
kubectl get jobs         # COMPLETIONS — did it finish?
kubectl logs job/pi-once # what the code actually printed
```

Finished Jobs and their Pods are kept **on purpose** so the last command works. `pi-once` sets `ttlSecondsAfterFinished: 600` to clean itself up anyway.

## Deletion cascades

```bash
kubectl delete cronjob every-minute    # takes its Jobs, which take their Pods
kubectl delete -f jobs-and-cronjob.yaml
```

Every object carries an `ownerReferences` entry pointing at its owner, and garbage collection follows it — the same rule that makes deleting a Namespace or a Deployment take everything below it.
