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

## Chapter 06 — DaemonSets

```bash
# There is no `kubectl create daemonset` — generate a Deployment and edit three things:
#   kind: Deployment -> DaemonSet · delete spec.replicas · delete spec.strategy (or use spec.updateStrategy)
kubectl create deployment logger --image=alpine --dry-run=client -o yaml \
  -- /bin/sh -c "while true; do date +'%Y-%m-%d-%H:%M:%S - Hello from \$NODE_NAME'; sleep 30; done" | tee logger.yaml

kubectl apply -f logger.yaml
kubectl get daemonset                                   # DESIRED = eligible NODES, not a number you set
kubectl get ds -A                                       # kube-proxy and the CNI agent are DaemonSets
kubectl get pods -o wide                                # named logger-<suffix>: no ReplicaSet in the middle
kubectl get pod <ds-pod> -o jsonpath='{.metadata.ownerReferences[0].kind}{"\n"}'   # DaemonSet, not ReplicaSet
kubectl logs -l app=logger --prefix                     # one line per node, labelled by Pod
kubectl describe daemonset logger

# DESIRED lower than your node count? Look at taints.
kubectl get nodes -o custom-columns='NAME:.metadata.name,TAINTS:.spec.taints[*].key'
kubectl describe node <control-plane> | grep -A3 Taints # node-role.kubernetes.io/control-plane:NoSchedule
kubectl get ds kube-proxy -n kube-system -o jsonpath='{.spec.template.spec.tolerations}'   # how kube-proxy gets on there anyway
kubectl taint nodes <node> node-role.kubernetes.io/control-plane:NoSchedule-   # trailing - REMOVES the taint (broad: opens it to everything)

# Coverage follows node labels
kubectl label node worker-1 gpu=true                    # a nodeSelector: gpu=true DaemonSet gains a Pod here
kubectl label node worker-1 gpu-                        # and loses it again

# Rollouts — same verbs, different defaults (maxUnavailable 1, maxSurge 0, or OnDelete)
kubectl rollout status  ds/logger
kubectl rollout history ds/logger
kubectl rollout restart ds/logger
kubectl rollout undo    ds/logger

kubectl delete -f logger.yaml
```

## Chapter 07 — set image and patch

```bash
# kubectl set image <type>/<name> <CONTAINER-NAME>=<image>
# the left of the = is the CONTAINER name from the pod template, not the resource name
kubectl get deployment web -o wide                          # CONTAINERS and IMAGES columns, side by side
kubectl get deployment web -o jsonpath='{.spec.template.spec.containers[*].name}{"\n"}'
kubectl set image deployment/web nginx=nginx:1.27           # .spec.template changed -> new RS -> rolling update
kubectl set image deployment/web nginx=nginx:1.27 sidecar=busybox:1.36   # several containers, named
kubectl set image daemonset/abc '*=nginx:1.9.1'             # WILDCARD = every container gets THIS SAME image
kubectl set image pod/nginx nginx=nginx:alpine-slim         # on a bare Pod: container restarts IN PLACE, same IP, no revision
kubectl set image deployments,rc nginx=nginx:1.9.1 --all    # all resources of those types in the namespace
kubectl set image deployment -l app=web nginx=nginx:1.27    # by label
kubectl set image deployment/web nginx=nginx:1.27 --dry-run=client -o yaml
kubectl set image -f deploy.yaml nginx=nginx:1.9.1 --local -o yaml   # edit a FILE, never contact the server
kubectl set resources deployment/web -c=nginx --limits=cpu=200m,memory=512Mi   # the same family: resources, env, serviceaccount, selector, subject

# Verify — spec vs reality
kubectl rollout status deployment/web                       # did it finish?
kubectl get deployment web -o wide                          # what the SPEC says
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].image}{"\n"}{end}'   # what is RUNNING

# kubectl patch — three types, default is strategic
kubectl patch deployment web -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","image":"nginx:1.27"}]}}}}'
                                                            # strategic: merges the list BY NAME (patchMergeKey), sidecar survives
kubectl patch deployment web --type=merge -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","image":"nginx:1.27"}]}}}}'
                                                            # merge (RFC 7386): REPLACES the whole list — sidecar deleted
kubectl patch deployment web --type=json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/image","value":"nginx:1.27"}]'
                                                            # json (RFC 6902): by position; ops add/remove/replace/copy/move/test
kubectl patch deployment web --type=json -p '[{"op":"add","path":"/spec/template/spec/containers/-","value":{"name":"busybox","image":"busybox","args":["sleep","infinity"]}}]'
                                                            # trailing - appends to the list; only JSON Patch can append or remove
kubectl patch deployment web --type=merge -p '{"metadata":{"annotations":{"old-key":null}}}'   # merge patch: null DELETES a key
kubectl patch deployment web --subresource=scale --type=merge -p '{"spec":{"replicas":2}}'     # scale without touching the spec
kubectl patch node k8s-node-1 -p '{"spec":{"unschedulable":true}}'

# Patch FILES — YAML works for all three types (kubectl converts YAML to JSON before reading --type), so no yq needed
kubectl patch deployment web --patch-file=patch.yaml
kubectl patch deployment web --type=json --patch-file=add-container.yaml
cat patch.yaml | yq -o=json -I=0                            # one-line JSON when a file is not an option

# JSON Pointer paths: zero-based index · - appends · ~1 escapes a literal /
kubectl patch deployment web --type=json -p '[{"op":"add","path":"/metadata/annotations/kubernetes.io~1change-cause","value":"bump to 1.27"}]'
# Deployment: /spec/template/spec/containers/0/image  ·  bare Pod: /spec/containers/0/image

kubectl set image --help | more                             # pipe a long help page into a pager (less is better: / to search, q to quit)
```

## Chapter 08 — Services

```bash
# Create one from a Deployment: expose copies the SELECTOR and the PORT
kubectl create deployment nginx --image=nginx --port=80 --replicas=3
kubectl expose deployment/nginx                              # type defaults to ClusterIP
kubectl expose deployment/nginx --dry-run=client -o yaml     # see the selector it will inherit
kubectl expose deployment/nginx --type=NodePort
kubectl expose deployment/nginx --type=LoadBalancer --port 8080 --target-port 80
kubectl create service clusterip|nodeport|loadbalancer|externalname   # EXACTLY four subcommands = four types
kubectl create service externalname my-service --external-name nginx-red.default.svc.cluster.local

# Look at it
kubectl get services                                         # PORT(S) 80:32610 = SERVICE port : NODE port
kubectl get svc -o wide                                       # adds SELECTOR
kubectl describe service nginx                                # Selector, Type, IP, Port, TargetPort, Endpoints
kubectl get endpoints                                         # the ready Pod IPs — SAME NAME as the Service
kubectl get endpointslices                                    # the modern API (Endpoints deprecated in 1.33)
kubectl get endpointslice -l kubernetes.io/service-name=nginx -o yaml
kubectl get pods -o wide                                      # cross-check: do these IPs appear in the endpoints?

# Reach it
curl 10.43.22.69                                              # ClusterIP, from a node or a Pod
curl 172.18.0.3:32610                                         # NodePort, via ANY node's IP
kubectl port-forward service/nginx 8080:80                    # from your laptop

# The throwaway test Pod — worth memorising
kubectl run -it --rm curl --image=curlimages/curl --restart=Never -- sh
  cat /etc/resolv.conf                                        # search default.svc.cluster.local ... ndots:5
  nslookup nginx                                              # ClusterIP: ONE answer · headless: ONE PER POD
  curl nginx                                                  # short name works inside the namespace
  curl nginx.other-ns                                         # across namespaces needs the qualifier
  exit
kubectl run -it --rm curl --image=curlimages/curl --restart=Never -- curl -s nginx    # one-shot
kubectl run -it --rm net --image=busybox:1.36 --restart=Never -- sh                   # nslookup, wget, ping

# Headless: clusterIP None. Not a type — a ClusterIP with no IP.
kubectl get svc nginx-headless                                # CLUSTER-IP column reads None
kubectl run -it --rm curl --image=curlimages/curl --restart=Never -- nslookup nginx-headless   # the Pod IPs
# StatefulSet + headless gives per-Pod names: web-0.<svc>.<ns>.svc.cluster.local

kubectl delete service/nginx
```

## Chapter 09 — Jobs and CronJobs

```bash
# Jobs — run to completion
kubectl create job calculatepi --image=perl:5.34.0 -- perl -Mbignum=bpi -wle "print bpi(2000)"
kubectl create job calculatepi --image=perl:5.34.0 --dry-run=client -o yaml -- perl -Mbignum=bpi -wle "print bpi(2000)" | tee job.yaml
kubectl get jobs                                        # COMPLETIONS reads succeeded/wanted · DURATION is how long it took
watch kubectl get jobs,pods
kubectl logs job/calculatepi                            # finished Pods are KEPT on purpose so this works
kubectl describe job calculatepi
kubectl get pods --selector=batch.kubernetes.io/job-name=calculatepi
kubectl explain job.spec.completions                    # "the desired number of SUCCESSFULLY FINISHED pods"
kubectl explain job.spec.parallelism                    # "the maximum desired number of pods ... AT ANY GIVEN TIME"

# The three patterns — it all hinges on whether completions is set
#   both unset      -> non-parallel (both default to 1)
#   completions: N  -> fixed count; parallelism caps concurrency
#   completions nil -> WORK QUEUE; any Pod's success completes the Job
kubectl patch job batch-fixed -p '{"spec":{"parallelism":0}}'    # 0 PAUSES a Job

# CronJobs — create Job objects on a schedule
kubectl create cronjob calculatepi --image=perl:5.34.0 --schedule="*/5 * * * *" -- perl -Mbignum=bpi -wle "print bpi(200)"
kubectl get cronjobs                                    # SCHEDULE · SUSPEND · ACTIVE · LAST SCHEDULE
kubectl get jobs                                        # one per fired schedule: <cronjob>-<timestamp>
kubectl logs job/calculatepi-29388420
kubectl create job manual-run --from=cronjob/calculatepi   # fire one NOW, off-schedule
kubectl patch cronjob calculatepi -p '{"spec":{"suspend":true}}'   # stop future runs, keep the object

# Deletion cascades DOWN the ownerReferences chain
kubectl delete cronjob calculatepi                      # → its Jobs → their Pods
kubectl delete job calculatepi                          # → its Pods
kubectl delete job calculatepi --cascade=orphan         # leave the Pods running (rarely wanted)
```

Defaults: `backoffLimit` **6** · `completions`/`parallelism` **1** when unset · `concurrencyPolicy` **Allow** · `successfulJobsHistoryLimit` **3** · `failedJobsHistoryLimit` **1**. A Job Pod's `restartPolicy` must be **`Never` or `OnFailure`** — never `Always`. Schedule fields: **minute hour day-of-month month day-of-week** ([crontab.guru](https://crontab.guru/)).

## Chapter 10 — ConfigMaps

```bash
# Create — three sources, three very different results
kubectl create configmap demo --from-literal=colour=blue --from-literal=size=large   # one key per flag
kubectl create configmap demo --from-file=app.properties            # ONE key (the basename), value = the WHOLE file
kubectl create configmap demo --from-file=cfg=app.properties        # same, but the key is renamed to cfg
kubectl create configmap demo --from-file=./config-dir/             # every file in the directory becomes a key
kubectl create configmap demo --from-env-file=app.properties        # ONE KEY PER LINE of key=value; the filename is gone
kubectl create configmap demo --from-literal=colour=blue --append-hash   # demo-9f8cbt2k4m — how Kustomize forces a rollout

# Generate the manifest instead of typing it
kubectl create configmap demo --from-literal=colour=blue --from-file=app.properties --dry-run=client -o yaml | tee demo-cm.yaml
kubectl apply -f demo-cm.yaml

# Inspect
kubectl get configmaps                                   # or cm
kubectl get cm demo -o yaml                              # values are PLAIN TEXT — this is not a Secret
kubectl describe cm demo
kubectl get cm demo -o jsonpath='{.data.colour}{"\n"}'
kubectl get cm demo -o jsonpath='{.data.app\.properties}'   # escape the dot in a key name

# Change one, and watch what notices
kubectl patch configmap demo --type=merge -p '{"data":{"colour":"green"}}'
kubectl edit configmap demo
kubectl exec mypod -- cat /etc/config/colour             # volume mount: updates within a kubelet sync period
kubectl exec mypod -- printenv COLOUR                    # env var: NEVER updates — needs a Pod restart
kubectl exec mypod -- cat /etc/single/app.properties     # subPath mount: NEVER updates either
kubectl rollout restart deployment/web                   # the standard way to pick up new config

kubectl delete configmap demo
```

Consuming one: `env` + `configMapKeyRef` (one key) · `envFrom` + `configMapRef` (all keys; invalid variable names are **skipped**) · a **volume mount** (each key becomes a file) · a volume mount with **`subPath`** (one key, one file). The Pod and the ConfigMap must be in the **same namespace**; a missing one blocks startup unless `optional: true`. Limit **1 MiB**; `immutable: true` **cannot be reverted**.

## Chapter 11 — Secrets

```bash
# Create — three subcommands, matching the three common types
kubectl create secret generic db-creds --from-literal=username=admin --from-literal=password=supersecret   # → Opaque
kubectl create secret generic ssh-key --from-file=ssh-privatekey=$HOME/.ssh/id_rsa
kubectl create secret generic app-env --from-env-file=app.env        # same --from-* semantics as ConfigMaps
kubectl create secret docker-registry regcred --docker-server=registry.example.com --docker-username=me --docker-password=pw
kubectl create secret tls my-site-tls --cert=tls.crt --key=tls.key   # → kubernetes.io/tls, needs tls.crt + tls.key
kubectl create secret generic db-creds --from-literal=password=pw --dry-run=client -o yaml | tee secret.yaml

# Inspect — and see why "encoded, not encrypted" matters
kubectl get secrets                                      # TYPE column · DATA = number of KEYS, not bytes
kubectl describe secret db-creds                         # values REDACTED here...
kubectl get secret db-creds -o yaml                      # ...but plainly base64 here
kubectl get secret db-creds -o jsonpath='{.data.password}' | base64 -d    # one command undoes it
kubectl get secret my-site-tls -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout -subject -dates

# Who can read them (chapter 04-04 RBAC)
kubectl auth can-i get secrets
kubectl auth can-i list secrets --as=system:serviceaccount:default:default
# list or watch on Secrets = read EVERY Secret in the namespace
# anyone who can create a Pod can mount a Secret and print it

kubectl delete secret db-creds
```

Consuming one: `env` + **`secretKeyRef`** (one key) · `envFrom` + **`secretRef`** (all keys; invalid variable names are skipped) · a **`secret` volume** (each key a file, held in **tmpfs**) · **`imagePullSecrets`** for private registries. Types: **`Opaque` (default)**, `service-account-token`, `dockercfg`, `dockerconfigjson`, `basic-auth`, `ssh-auth`, **`kubernetes.io/tls`**, `bootstrap.kubernetes.io/token`. **`data`** = base64 · **`stringData`** = plaintext, write-only. 1 MiB; `immutable: true` cannot be reverted.

## Chapter 12 — Labels and selectors

```bash
# See them
kubectl get pods --show-labels
kubectl get pods -L colour -L tier                  # labels as COLUMNS, one per -L
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.labels}{"\n"}{end}'

# Equality-based — the ONLY grammar a Service or ReplicationController can use
kubectl get pods -l colour=red
kubectl get pods -l colour==red                     # == is a synonym for =
kubectl get pods -l colour=red,tier=backend         # comma is AND
kubectl get pods -l 'colour!=red'                   # ALSO matches objects with no colour key at all

# Set-based — Deployment · ReplicaSet · DaemonSet · StatefulSet · Job · NetworkPolicy
kubectl get pods -l 'colour in (red,pink)'
kubectl get pods -l 'colour notin (green)'
kubectl get pods -l colour                          # the key exists, any value
kubectl get pods -l '!colour'                       # the key does NOT exist
kubectl get pods -l 'partition in (a,b),environment!=qa'   # the two grammars mix

# Selectors work on any command, and across kinds
kubectl get all --selector run=nginx                # the Pod AND the Service it was exposed as
kubectl get pods -l app=web -A                      # selectors are NAMESPACE-SCOPED — -A for all
kubectl logs -l app=web --prefix --tail=20
kubectl delete pods -l colour=pink
kubectl describe pods -l tier=backend

# Add, change and remove labels
kubectl label pod ubuntu-red colour=red
kubectl label pod ubuntu-red colour=crimson --overwrite    # required to change an existing key
kubectl label pod ubuntu-red colour-                       # trailing - REMOVES the label
kubectl label pods --all env=dev
kubectl label node worker-1 disktype=ssd                   # node labels drive nodeSelector and affinity
kubectl annotate deployment/web kubernetes.io/change-cause="..."   # annotations: NOT selectable

# Who is selecting on them
kubectl get svc palette -o jsonpath='{.spec.selector}{"\n"}'
kubectl get deploy web -o jsonpath='{.spec.selector}{"\n"}'
kubectl get endpoints palette                       # relabel a Pod and watch membership change
```

Key syntax: optional **prefix** (DNS subdomain, ≤253) + **name** (≤63); **values ≤63 chars, may be empty**; **`kubernetes.io/` and `k8s.io/` are reserved**. Labels are **selectable**, annotations are **not**.

## The API behind kubectl

```bash
kubectl get pods -v=8 2>&1 | grep -E 'GET|Response Status'   # the REST calls kubectl is making
kubectl proxy &  ;  curl -s localhost:8001/api/v1/namespaces/default/pods | head   # the API without kubectl
kubectl api-resources                                          # every kind the API server knows, incl. CRDs
kubectl api-versions
kubectl explain pod.spec                                       # the PodSpec, field by field
```
