# kubectl basics — commands

Companion to [`../04-kubernetes-fundamentals/`](../04-kubernetes-fundamentals/). Grows chapter by chapter through Section 4. Assumes a working context (Docker Desktop's `docker-desktop`, or a kind/kubeadm cluster — see [`setup.md`](setup.md)).

## Chapter 01 — seeing the architecture

```bash
# The cluster and its nodes
kubectl cluster-info                                   # API server URL (the load balancer, in HA) and CoreDNS
kubectl get nodes -o wide                              # every kubelet that registered: roles, version, OS, kernel, container runtime
kubectl describe node <node> | grep -A5 Taints         # the control plane taint that keeps app Pods off it (absent on single-node clusters)

# The control plane, as Pods
kubectl get pods -n kube-system -o wide                # etcd-*, kube-apiserver-*, kube-controller-manager-*, kube-scheduler-* = static pod mirrors
                                                       # kube-proxy-* (DaemonSet), coredns-* (Deployment) = normal Pods
kubectl get pods -n kube-system -o custom-columns='NAME:.metadata.name,OWNER:.metadata.ownerReferences[0].kind'
                                                       # static pods are owned by Node; kube-proxy by DaemonSet; coredns by ReplicaSet
kubectl get daemonset,deployment -n kube-system         # kube-proxy: 1 per node · coredns: 2 replicas

# Mirror pods are read-only — the file wins
kubectl delete pod kube-scheduler-<node> -n kube-system   # comes straight back; the manifest on disk recreated it
kubectl get pod kube-scheduler-<node> -n kube-system -o yaml | grep -E 'kubernetes.io/config.(source|mirror)'   # source: file

# On the control plane host itself (kubeadm / kind: docker exec -it <node> bash)
ls /etc/kubernetes/manifests/                          # etcd.yaml kube-apiserver.yaml kube-controller-manager.yaml kube-scheduler.yaml
grep staticPodPath /var/lib/kubelet/config.yaml        # where the kubelet is told to look
systemctl status kubelet                               # the one component that is a host service, not a container
ls /etc/kubernetes/pki/                                # the certificates static pods mount with hostPath

# etcd — the source of truth (needs the certs in /etc/kubernetes/pki/etcd)
kubectl exec -n kube-system etcd-<node> -- etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key \
  member list -w table                                 # members and the leader; endpoint status for the DB size and Raft term
# every object is a key: get /registry/pods/default/nginx --prefix --keys-only

# Watch the flow in section 7.1 happen
kubectl run nginx --image=nginx
kubectl get pod nginx -w                               # Pending → ContainerCreating → Running
kubectl get events --sort-by=.metadata.creationTimestamp | tail   # Scheduled (by default-scheduler) · Pulling · Pulled · Created · Started (by kubelet)
kubectl get pod nginx -o jsonpath='{.spec.nodeName}{"\n"}'   # the field the scheduler wrote
kubectl delete pod nginx
```

## Chapter 01 further study — find vs reach

```bash
# The find layer: CoreDNS
kubectl get deployment,service -n kube-system -l k8s-app=kube-dns      # Deployment coredns (2 replicas) · Service kube-dns (the ClusterIP every Pod's resolv.conf points at)
kubectl run dnstest --image=busybox:1.36 --restart=Never -- sleep 3600
kubectl exec dnstest -- cat /etc/resolv.conf                            # nameserver 10.96.0.10 · search default.svc.cluster.local svc.cluster.local cluster.local
kubectl exec dnstest -- nslookup kubernetes                             # short name → kubernetes.default.svc.cluster.local → the API server's ClusterIP
kubectl exec dnstest -- nslookup kube-dns.kube-system.svc.cluster.local # full name across namespaces
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=5                # CoreDNS answering (enable the log plugin in the Corefile to see queries)

# The reach layer: Pod IPs and the CNI
kubectl get pods -A -o wide                                             # every Pod has its own IP; note the per-node subnets (10.244.<node>.x)
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.podCIDR}{"\n"}{end}'   # the Pod subnet each node was given
kubectl get pods -n kube-system -o wide | grep -Ei 'flannel|calico|cilium|weave'   # which CNI provider is installed (a DaemonSet, one agent per node)
kubectl exec dnstest -- ping -c1 <ip-of-a-pod-on-another-node>          # Pod-to-Pod across nodes, no NAT — the CNI's routes/encapsulation at work
# on a node: ip route (a route per remote podCIDR = routed CNI) · ip -d link show flannel.1 (VXLAN = overlay) · ls /etc/cni/net.d
kubectl delete pod dnstest
```

## Chapter 02 — Pods

```bash
# Create and inspect
kubectl run nginx --image=nginx                         # imperative; kubectl run only ever creates a Pod
kubectl run nginx --image=nginx --restart=Never         # sets spec.restartPolicy (default Always)
kubectl run nginx --image=nginx --port=80 --labels=app=web,tier=frontend
kubectl get pods                                        # NAME READY STATUS RESTARTS AGE
kubectl get pods -o wide                                # adds IP and NODE — the two columns this chapter is about
kubectl get pods -A                                     # every namespace
kubectl get pods -w                                     # watch state changes as they happen
kubectl get pod nginx -o yaml                           # the stored object, with defaults and status filled in
kubectl describe pod nginx                              # spec, per-container status, and Events at the bottom
kubectl get pod nginx -o jsonpath='{.status.podIP}{"\n"}'
kubectl get pods -o custom-columns='NAME:.metadata.name,IP:.status.podIP,NODE:.spec.nodeName'

# Logs
kubectl logs nginx
kubectl logs mypod -c sidecar                           # -c is required once the Pod has more than one container
kubectl logs -f mypod -c sidecar                        # follow
kubectl logs mypod --previous                           # the log of the container instance that crashed, not the running one
kubectl logs mypod --tail=20 --timestamps
kubectl logs --selector run=mypod --all-containers      # by label instead of by name
until kubectl logs pod/countdown-pod -c init-countdown --follow --pod-running-timeout=5m; do sleep 1; done   # retry until it is startable

# Exec — everything after -- is the container's command, not kubectl's
kubectl exec mypod -- ls /usr/share/nginx/html
kubectl exec -it mypod -- bash                          # sh if the image has no bash
kubectl exec -it mypod -c sidecar -- bash
kubectl exec mypod -c sidecar -- touch /tmp/crash       # make that container exit 1; RESTARTS climbs for it alone

# Pod to Pod, from inside the cluster
kubectl get pod nginx -o wide                           # read the IP, e.g. 10.42.2.7
kubectl exec -it mypod -- curl http://10.42.2.7         # any Pod reaches any Pod, no NAT
kubectl run tmp --image=curlimages/curl -it --rm --restart=Never -- curl -s http://10.42.2.7   # throwaway client, deleted on exit
kubectl run tmp --image=busybox:1.36 -it --rm --restart=Never -- sh   # nslookup, wget, ping in a scratch Pod

# From outside the cluster network
kubectl port-forward pod/nginx 8080:80                  # then http://localhost:8080 — TCP only, one client, ctrl-c ends it
kubectl port-forward pod/nginx :80                      # let kubectl pick the local port
kubectl port-forward deployment/mongo 28015:27017       # also works on deployment/, replicaset/, service/

# Delete
kubectl delete pod nginx
kubectl delete pod nginx --now                          # skip the 30s graceful shutdown
kubectl delete pods --all
kubectl delete -f combined.yaml                         # delete exactly what a manifest created
```

### Generating manifests, applying them, and looking up fields

```bash
# Generate rather than type
kubectl run mypod --image=nginx --dry-run=client -o yaml                    # built locally and printed; the API server is never contacted
kubectl run mypod --image=nginx --dry-run=client -o yaml | tee mypod.yaml   # print AND save — tee writes the file and passes the text through
kubectl create deployment web --image=nginx --dry-run=client -o yaml | tee web.yaml
kubectl get pod mypod -o yaml | tee snapshot.yaml                           # the same trick against a live object

# Apply — declarative
kubectl apply -f mypod.yaml
kubectl diff -f mypod.yaml                                                  # what apply would change, before it changes it
kubectl apply --dry-run=server -f mypod.yaml                                # validated, defaulted and admitted by the API server, then discarded
kubectl apply -f nginx.yaml -f ubuntu.yaml                                  # several files
kubectl apply -f ./manifests/                                               # or a whole directory
{ cat nginx.yaml; echo "---"; cat ubuntu.yaml; } | tee combined.yaml        # one artifact out of several — the ; before } is required
kubectl apply -f combined.yaml

# The field reference, with no internet
kubectl explain pod
kubectl explain pod.spec
kubectl explain pod.spec.containers
kubectl explain pod.spec.restartPolicy                                      # prints the allowed values: Always, OnFailure, Never
kubectl explain pod.spec.containers --recursive                             # every field below this point, names only
```

## Chapter 03 — Troubleshooting Pods

```bash
# Where did it get to?
kubectl get pods                                        # the STATUS column: a container reason, not the Pod phase
kubectl get pod ubuntu -o jsonpath='{.status.phase}{"\n"}'   # the actual phase: Pending|Running|Succeeded|Failed|Unknown
kubectl get pod ubuntu -o jsonpath='{.spec.nodeName}{"\n"}'  # empty = never scheduled
kubectl describe pod ubuntu                             # Events at the bottom; State / Last State / Reason / Message; Conditions
kubectl get pod ubuntu -o yaml | grep -A12 'containerStatuses:'   # the same states, raw

# Events — the purpose-built command
kubectl events                                          # this namespace
kubectl events --for pod/ubuntu                         # only this object
kubectl events --for pod/ubuntu --watch                 # and keep streaming
kubectl events --types=Warning                          # or Warning,Normal
kubectl events -A
# the older form, still everywhere:
kubectl get events --sort-by=.metadata.creationTimestamp
kubectl get events --field-selector involvedObject.name=ubuntu,type=Warning
# events expire (API server --event-ttl, about an hour) — a long-broken Pod shows Events: <none>

# Logs — only if the container actually started (RESTARTS > 0)
kubectl logs ubuntu
kubectl logs ubuntu -p                                  # --previous: the instance that crashed — the one with the error
kubectl logs -f --tail=20 ubuntu                        # recent context, then live: the pair worth memorising
kubectl logs ubuntu -c ubuntu -f --tail=20              # and pick the container
kubectl logs ubuntu --all-containers -f --tail=20       # every container in the Pod in one stream
kubectl logs ubuntu --all-containers --prefix           # prefix each line with pod/container so it stays readable
kubectl logs --since=15m ubuntu ; kubectl logs --timestamps ubuntu
kubectl logs -l run=ubuntu --all-containers -f          # across Pods by label (--max-log-requests defaults to 5)
# container never started? kubectl logs answers:
#   Error from server (BadRequest): container "ubuntu" in pod "ubuntu" is waiting to start: trying and failing to pull image

# Exec — the Pod runs but does the wrong thing
kubectl exec ubuntu -- env                              # what the container actually sees
kubectl exec ubuntu -- cat /etc/resolv.conf
kubectl exec -it ubuntu -c ubuntu -- bash               # interactive shell (-i stdin, -t TTY, both needed)
kubectl exec -it ubuntu -- sh                           # if the image has no bash
kubectl debug -it ubuntu --image=busybox:1.36 --target=ubuntu   # distroless/scratch: attach an ephemeral container

# Change a Pod and watch it come back (most of a Pod's spec is immutable)
kubectl replace --force=true --grace-period=0 -f ubuntu.yaml; kubectl get pods --watch
```

## Chapter 04 — Namespaces

```bash
# The tour
kubectl get namespaces                                  # or ns — default, kube-system, kube-public, kube-node-lease
kubectl get all -A                                      # every namespace at once (but "all" is a category, not everything)
kubectl get all -n kube-system                          # what the system runs
kubectl get service kubernetes                          # in DEFAULT, not kube-system: the API server's ClusterIP
kubectl get configmap cluster-info -n kube-public       # the one thing unauthenticated clients may read
kubectl get leases -n kube-node-lease                   # one per node — the kubelet heartbeat

# Is this kind namespaced?
kubectl api-resources --namespaced=true
kubectl api-resources --namespaced=false                # Node, Namespace, PV, StorageClass, ClusterRole, CRD ...
kubectl api-resources | more                            # the full table one screen at a time (space = next page, q = quit)
kubectl api-resources | grep -i persistentvolume        # SHORTNAMES, APIVERSION, NAMESPACED, KIND
kubectl api-resources --api-group=rbac.authorization.k8s.io

# Using them
kubectl create namespace team-a
kubectl run nginx --image=nginx -n team-a
kubectl get pods -n team-a
kubectl get pods -A                                     # --all-namespaces
kubectl describe namespace team-a                       # includes any ResourceQuota and LimitRange in effect
kubectl delete namespace team-a                         # deletes EVERYTHING inside it

# Quotas and limits
kubectl get resourcequota,limitrange -n team-a
kubectl describe resourcequota team-a-quota -n team-a   # Used vs Hard, line by line

# Stop typing -n: the namespace is part of the context
kubectl config set-context --current --namespace=team-a
kubectl config view --minify | grep namespace:
kubectl config get-contexts                             # * marks the current one
kubectl config current-context
kubectl config use-context docker-desktop
# kubectx / kubens wrap the two above for daily use (not exam material)
```

## Chapter 05 — Deployments and ReplicaSets

```bash
# Create, and see the whole chain
kubectl create deployment nginx --image=nginx
kubectl create deployment nginx --image=nginx --replicas=3 --port=80
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml | tee nginx-deployment.yaml | kubectl apply -f -
                                                        # tee writes the file AND pipes it on; the lone - means "read from stdin"
kubectl get deployment,replicaset,pods                  # nginx → nginx-77b4fdf86c → nginx-77b4fdf86c-qrfpm
kubectl get deployment -o wide                          # CONTAINERS, IMAGES, SELECTOR
kubectl get rs -o wide                                  # DESIRED / CURRENT / READY per ReplicaSet
kubectl get pods --show-labels                          # pod-template-hash=77b4fdf86c on every Pod
kubectl describe deployment nginx                       # StrategyType, RollingUpdateStrategy, OldReplicaSets, NewReplicaSet

# Scale the DEPLOYMENT — there is no scaling a Pod
kubectl scale deployment nginx --replicas=12
kubectl scale deployment nginx --current-replicas=12 --replicas=6   # only act if it is currently 12
kubectl rollout history deployment/nginx                # unchanged: scaling is not a revision

# Trigger a rollout — only .spec.template changes count
kubectl set image deployment/nginx nginx=nginx:1.27     # <container-name>=<new-image>
kubectl edit deployment nginx
kubectl apply -f nginx-deployment.yaml
kubectl set resources deployment/nginx -c=nginx --limits=cpu=200m,memory=512Mi
kubectl rollout restart deployment/nginx                # same image, fresh Pods (re-read a ConfigMap, clear bad state)

# Watch it
kubectl rollout status deployment/nginx                 # blocks until done; non-zero exit if it fails
kubectl get replicaset -w                               # old RS scaling down, new RS scaling up
watch kubectl get pods -o wide                          # at 12 replicas: never below 9 available, never above 15 total

# History and why each revision happened
kubectl annotate deployment/nginx kubernetes.io/change-cause="bump to 1.27" --overwrite   # set BEFORE the change
kubectl rollout history deployment/nginx                # REVISION + CHANGE-CAUSE (--record is deprecated)
kubectl rollout history deployment/nginx --revision=3   # labels, image and ports of that revision

# Roll back
kubectl rollout undo deployment/nginx                   # back one revision
kubectl rollout undo deployment/nginx --to-revision=4   # to a specific one
kubectl rollout history deployment/nginx                # the number you rolled back TO is now gone — it was re-annotated
kubectl get rs -o custom-columns='NAME:.metadata.name,REV:.metadata.annotations.deployment\.kubernetes\.io/revision,DESIRED:.spec.replicas'

# Batch several changes into one rollout
kubectl rollout pause deployment/nginx
kubectl set image deployment/nginx nginx=nginx:1.27
kubectl rollout resume deployment/nginx

kubectl delete deployment nginx                         # takes the ReplicaSets and Pods with it
```

## The API behind kubectl

```bash
kubectl get pods -v=8 2>&1 | grep -E 'GET|Response Status'   # the REST calls kubectl is making
kubectl proxy &  ;  curl -s localhost:8001/api/v1/namespaces/default/pods | head   # the API without kubectl
kubectl api-resources                                          # every kind the API server knows, incl. CRDs
kubectl api-versions
kubectl explain pod.spec                                       # the PodSpec, field by field
```
