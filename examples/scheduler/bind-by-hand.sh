#!/usr/bin/env bash
# Be your own scheduler, once, by hand.
#
# The entire contract a Kubernetes scheduler has to satisfy is:
#   1. find a Pod whose spec.schedulerName is yours and whose spec.nodeName is null
#   2. decide a node, by any means you like
#   3. write a Binding object naming that Pod and that Node
#
# This script does step 3 for a single Pod so you can watch it happen. The
# course's loop version of the same idea is at
# https://github.com/spurin/simple-kubernetes-scheduler-example
set -euo pipefail

POD="${1:-sched-custom}"
NS="${2:-default}"

echo "== The Pod is Pending because nothing claims its schedulerName =="
kubectl -n "$NS" get pod "$POD" -o custom-columns=\
NAME:.metadata.name,STATUS:.status.phase,SCHEDULER:.spec.schedulerName,NODE:.spec.nodeName

# Step 2: "decide" a node. Filtering and scoring, replaced by picking the first
# one. Kubernetes does not care how the decision is made, only that it is made.
NODE=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
echo
echo "== Binding $NS/$POD to $NODE =="

# Step 3: the Binding object. Note `kubectl create`, NOT `kubectl apply` --
# Binding is a special resource that is written once, never reconciled, so
# apply's create-or-update semantics do not fit it.
kubectl create -f - <<EOF
apiVersion: v1
kind: Binding
metadata:
  name: $POD
  namespace: $NS
target:
  apiVersion: v1
  kind: Node
  name: $NODE
EOF

echo
echo "== spec.nodeName is now set, and the kubelet on $NODE takes over =="
sleep 3
kubectl -n "$NS" get pod "$POD" -o custom-columns=\
NAME:.metadata.name,STATUS:.status.phase,SCHEDULER:.spec.schedulerName,NODE:.spec.nodeName
