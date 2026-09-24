# DaemonSets

Companion manifest for [`06-daemonsets`](../../notes/04-kubernetes-fundamentals/06-daemonsets.md).

| File | What it shows |
|---|---|
| [`logger-daemonset.yaml`](logger-daemonset.yaml) | A DaemonSet whose Pods print the node they are running on, via the downward API, so coverage is visible in one command. `updateStrategy` written out, plus commented-out blocks for the control-plane toleration and a `nodeSelector` |

```bash
kubectl apply -f logger-daemonset.yaml
kubectl get daemonset
kubectl logs -l app=logger --prefix
```

One line per node. `--prefix` labels each line with the Pod it came from.

## If `DESIRED` is lower than your node count

That is almost always a taint. On a kubeadm cluster the control-plane node carries `node-role.kubernetes.io/control-plane:NoSchedule`, and the tolerations the DaemonSet controller adds for free do not include it:

```bash
kubectl get nodes -o custom-columns='NAME:.metadata.name,TAINTS:.spec.taints[*].key'
```

Uncomment the `tolerations` block in the manifest to cover the control plane too. On k3s the server node is untainted by default, so full coverage happens without it — which is why the same manifest reports 3 of 3 there and 2 of 3 on kubeadm.

## The contrast worth running

```bash
kubectl create deployment logger-dep --image=alpine --replicas=6 -- /bin/sh -c "sleep infinity"
kubectl get pods -l app=logger-dep -o wide
kubectl delete deployment logger-dep
```

Count the Pods per node. Six replicas across three nodes will usually double up somewhere and may still miss one — and adding a node afterwards changes nothing, because the Deployment's desired state was a number and the number is still satisfied. That is the gap a DaemonSet closes.
