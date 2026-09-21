# Commands reference

> Docker, kubectl, and shell commands demonstrated in the hands-on lectures, collected in one page to `Ctrl+F`. The KCNA does not test typing — this exists so the labs are reproducible and so command *names* and *flags* that show up in questions ("which command lists the nodes?") are in one place. For focused per-topic files see [`commands/`](commands/).

## How to use this file

- `Ctrl+F` for the tool or resource (`docker run`, `kubectl get`, ...).
- Sections are added as the course reaches them. Empty sections are placeholders so the numbering is stable.

---

## 1. Local lab setup

Per-topic detail: [`commands/setup.md`](commands/setup.md).

```bash
docker version && docker info                 # engine inside the Docker Desktop VM: runtime, cgroups, kernel
kubectl config use-context docker-desktop     # after Settings → Kubernetes → Enable
kubectl get nodes                             # docker-desktop  Ready  control-plane
```

## 2. Docker

Full reference by noun (images, containers, networks, volumes, build, compose): [`commands/docker.md`](commands/docker.md). The blocks below are the exam-critical subset.

### 2a. The shared kernel (chapter 03-01)

```bash
docker run ubuntu uname -a          # every image reports the SAME kernel version —
docker run amazonlinux uname -a     # there is only one kernel, the host's
docker run centos uname -a
docker run ubuntu cat /etc/os-release   # what differs is userspace
docker run -it ubuntu bash              # -i keep STDIN open, -t pseudo-TTY; bash is PID 1, exit stops the container
docker run -d --name web nginx          # -d detached

# Namespaces and cgroups on a Linux host
lsns
ls -l /proc/$$/ns/
sudo unshare --pid --fork --mount-proc bash     # you are PID 1 in a new PID namespace
docker inspect -f '{{.State.Pid}}' <container>  # host PID of the container's process
sudo nsenter -t <pid> -n ip addr                # enter its network namespace
docker run -d --memory=256m --cpus=0.5 nginx    # limits become cgroup settings
docker stats --no-stream                        # cgroup accounting
```

### 2b. Images (chapter 03-03) — `docker image <verb>` = the traditional `docker <verb>`

```bash
docker image pull ubuntu:22.04                  # docker pull; no tag → :latest (a default, not "newest")
docker image pull IMAGE@sha256:<digest>         # immutable pull by content hash
docker image ls [--digests]                     # docker images
docker image inspect IMAGE                      # JSON: Config, RootFS.Layers, RepoDigests
docker image history IMAGE                      # instructions → layers (0 B = metadata only)
docker image tag SRC DST && docker image push DST
docker image rm IMAGE                           # docker rmi
docker image save IMAGE -o f.tar / docker image load -i f.tar
docker buildx imagetools inspect IMAGE [--raw]  # index/manifests per platform; --raw | sha256sum == the digest
docker container diff ID                        # the writable layer's A/C/D changes
```

### 2c. Container lifecycle (chapter 03-04)

```bash
docker container run  = create + start      # flags fixed at creation; CMD after the image replaces the image's CMD
docker container ls / ls -a                 # running / all states (created restarting running removing paused exited dead)
docker container stop C                     # SIGTERM → 10 s grace → SIGKILL
docker container kill C                     # SIGKILL now
docker container start C / restart C / pause C / unpause C
docker container rm C / rm -f C / prune     # remove stopped / running / all stopped
docker container exec -it C sh              # a new process inside (the way to get a shell)
docker container logs -f C                  # PID 1's stdout/stderr
docker container inspect / top / stats / port / diff / cp
--restart no | on-failure[:N] | always | unless-stopped
```

### 2d. Ports, networks, mounts (chapter 03-05)

```bash
docker run -p 12345:80 IMG                      # publish host:container (127.0.0.1:12345:80 to keep local; /udp)
docker run -P IMG ; docker container port C     # publish all EXPOSEd ports to random host ports; show mappings
docker network ls | create NET | inspect NET    # bridge (default, no DNS) · host · none · overlay; user-defined bridges have DNS by name
docker run --network NET --name db IMG          # "db" resolves for others on NET
docker run -v /abs/host/path:/ctr/path[:ro] IMG # bind mount (absolute; PowerShell "${PWD}\x", WSL /mnt/c/…)
docker run -v NAME:/ctr/path IMG                # named volume, created if missing, pre-populated from the image dir
docker run --mount type=bind|volume|tmpfs,src=…,dst=…[,readonly] IMG   # explicit form; --mount errors on a missing host path, -v creates a dir
docker volume create | ls | inspect | rm | prune
```

### 2e. Build and push (chapter 03-06)

```bash
docker build -t NAME:TAG .                      # ./Dockerfile; -f other; --no-cache; --pull; --target STAGE
docker image history NAME:TAG                   # layers per instruction
docker buildx build --platform linux/amd64,linux/arm64 -t user/app --push .   # multi-platform index
docker login ; docker tag NAME user/NAME:TAG ; docker push user/NAME:TAG
# Dockerfile: FROM (AS stage) · WORKDIR (not RUN cd) · RUN a && b (one layer) · COPY --from=stage
#             LABEL org.opencontainers.image.* · USER nonroot · ENTRYPOINT ["bin"] · CMD ["default","args"]
```

## 3. kubectl basics

Per-chapter detail: [`commands/kubectl-basics.md`](commands/kubectl-basics.md).

### 3a. The architecture, from kubectl (chapter 04-01)

```bash
kubectl cluster-info ; kubectl get nodes -o wide            # API endpoint; every registered kubelet with its runtime
kubectl get pods -n kube-system -o wide                     # etcd/apiserver/scheduler/c-m = static pod mirrors; kube-proxy = DaemonSet; coredns = Deployment
kubectl get daemonset,deployment -n kube-system
kubectl delete pod kube-scheduler-<node> -n kube-system     # a mirror pod comes straight back — the manifest file is the truth
ls /etc/kubernetes/manifests/                               # on the control plane host: the four static pod YAMLs
kubectl run nginx --image=nginx && kubectl get pod nginx -w # Pending (scheduler) → ContainerCreating (kubelet) → Running
kubectl get events --sort-by=.metadata.creationTimestamp    # Scheduled · Pulling · Pulled · Created · Started
kubectl get pods -v=8                                       # the REST calls behind the command
```

### 3b. Find vs reach — DNS and the CNI (chapter 04-01 further study)

```bash
kubectl exec <pod> -- cat /etc/resolv.conf                  # nameserver = kube-dns ClusterIP; search list makes short Service names work
kubectl exec <pod> -- nslookup my-svc                        # CoreDNS: name → ClusterIP
kubectl get pods -A -o wide ; kubectl get nodes -o jsonpath='{.items[*].spec.podCIDR}'   # unique Pod IPs, per-node subnets
kubectl get pods -n kube-system -o wide | grep -Ei 'flannel|calico|cilium'   # the CNI agent DaemonSet
```

## 4. Workloads and services

_Section 5._

### 4a. Autoscaling (from Section 2, chapter 03)

Full walkthrough: [`commands/autoscaling.md`](commands/autoscaling.md). Example manifest: `examples/autoscaling/hpa-cpu-memory.yaml`.

```bash
# metrics-server (prerequisite for HPA/VPA and kubectl top) — kind needs the insecure-tls flag
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl -n kube-system patch deployment metrics-server --type=json   -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
kubectl top nodes
kubectl top pods

# HPA
kubectl autoscale deployment web --cpu-percent=60 --min=2 --max=10   # CPU only; memory needs v2 YAML
kubectl get hpa
kubectl get hpa web -w
kubectl describe hpa web                                             # Events show each scaling decision

# Load generator
kubectl run -it load --rm --restart=Never --image=busybox:1.36 -- /bin/sh -c "while true; do wget -q -O- http://web; done"
```

## 5. Observability tooling

_Section 6._

## 6. Delivery tooling (Helm, GitOps)

_Section 7._
