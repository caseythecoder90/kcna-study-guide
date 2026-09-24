# Deployments

Companion manifest for [`05-deployments-and-replicasets`](../../notes/04-kubernetes-fundamentals/05-deployments-and-replicasets.md).

| File | What it shows |
|---|---|
| [`nginx-deployment.yaml`](nginx-deployment.yaml) | A Deployment with `strategy`, `maxSurge`, `maxUnavailable`, `revisionHistoryLimit`, `progressDeadlineSeconds` and `minReadySeconds` all written out instead of defaulted, at 12 replicas so the surge arithmetic is easy to watch |

```bash
kubectl apply -f nginx-deployment.yaml
kubectl get deployment,replicaset,pods
```

The file's comments walk through a five-step lab: create it, roll forward to a good image, roll forward to a broken one and watch `maxUnavailable` keep the old Pods serving while the new ReplicaSet sits in `ImagePullBackOff`, roll back, and then scale to prove that scaling adds no revision.

The step worth doing slowly is the rollback. After `kubectl rollout undo --to-revision=2`, the history reads **1, 3, 4** — revision 2 has vanished, because a revision number is an annotation on a ReplicaSet and rolling back re-annotates that same ReplicaSet with the next number. Revision numbers are not stable identifiers.

Watch a rollout in a second terminal with:

```bash
watch kubectl get pods -o wide
```

At 12 replicas the counts stay between 9 available and 15 total throughout.
