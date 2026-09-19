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

## 3. kubectl basics

_Section 4._

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
