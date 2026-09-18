# Docker — commands

Companion to [`../03-containers-with-docker/`](../03-containers-with-docker/). Grows chapter by chapter through Section 3. Docker Desktop (macOS/Windows) or Docker Engine (Linux) both work; on macOS/Windows remember the containers run inside a hidden Linux VM.

## Chapter 01 — the shared kernel

```bash
# Three distributions, one kernel: every container reports the host kernel's version
docker run ubuntu uname -a
docker run amazonlinux uname -a
docker run centos uname -a
# → all three print the same "5.15.49-linuxkit ..." (or your host's kernel on Linux)

# What differs is userspace — compare the OS release inside each image
docker run ubuntu cat /etc/os-release
docker run amazonlinux cat /etc/os-release
```

## Chapter 02 — first interactive container

```bash
docker run -it ubuntu bash        # -i keep STDIN open, -t allocate a pseudo-TTY; bash becomes PID 1
apt update && apt install -y htop # inside: root, no sudo needed
htop                              # bash = PID 1 (main process), htop = its child; CPU/mem shown are the VM's
exit                              # PID 1 exits → the container stops
docker ps -a                      # ... Exited (0) ...
docker rm <id>                    # or use --rm on the run to auto-remove
docker run -d --name web nginx    # -d detach: run in the background, print the container ID
docker stop web && docker rm web
```

## Chapter 03 — images, tags, layers, digests

Both CLI forms are shown: the management form `docker <noun> <verb>` (Docker 1.13+, self-documenting via `docker image --help`) and the traditional alias.

### Pull, list, inspect, remove

```bash
docker image pull spurin/funbox                 # = docker pull; default registry docker.io, default tag :latest
docker image pull docker.io/spurin/funbox:latest # the same reference, fully qualified
docker image pull ubuntu:22.04                  # explicit tag — prefer this over :latest everywhere that matters
docker image pull ghcr.io/org/app:1.2           # another registry: put the host in the name
docker image pull spurin/funbox@sha256:8a01842539972507846c938e120ecc1f5b9f921da77f4d0e81cae17f42f10b90   # by digest: immutable

docker image ls                                 # = docker images; REPOSITORY TAG IMAGE ID CREATED SIZE
docker image ls --digests                       # add the registry digest column
docker image ls -q                              # IDs only (handy for scripting: docker image rm $(docker image ls -q))
docker image inspect spurin/funbox              # full JSON: Config (Env, Cmd, User), RootFS.Layers (diff_ids), RepoDigests
docker image inspect --format '{{index .RepoDigests 0}}' spurin/funbox   # name@sha256:… — what to pin in a manifest
docker image history spurin/funbox              # one row per instruction: which created layers (size) vs 0 B metadata
docker image rm spurin/funbox                   # = docker rmi; fails if a container still uses it (-f to force)
docker image prune                              # delete dangling (untagged) images; -a for all unused
docker system df                                # disk used by images, containers (writable layers), volumes, build cache
```

### Tags

```bash
docker image tag spurin/funbox:latest myreg.local:5000/funbox:1.0.0   # = docker tag; a second name for the SAME image (same ID)
docker image ls | grep funbox                                          # two rows, one IMAGE ID
docker image push myreg.local:5000/funbox:1.0.0                        # = docker push; prints the digest at the end
docker login myreg.local:5000                                          # registry credentials (never in Dockerfiles)
```

### Digests — reproduce what the registry computed

```bash
docker buildx imagetools inspect spurin/funbox                 # Name / MediaType / Digest, then one manifest per platform
docker buildx imagetools inspect spurin/funbox --raw           # the index JSON exactly as stored
docker buildx imagetools inspect spurin/funbox --raw | sha256sum      # Linux: prints 8a01842… — the digest IS the hash
docker buildx imagetools inspect spurin/funbox --raw | shasum -a 256  # macOS
# Windows PowerShell: pipes re-encode text, so write the bytes via cmd and hash the file
#   cmd /c "docker buildx imagetools inspect spurin/funbox --raw > index.json"
#   Get-FileHash index.json -Algorithm SHA256
```

### The image on disk — OCI Image Layout

```bash
mkdir /tmp/funbox && cd /tmp/funbox
docker image save spurin/funbox -o funbox.tar      # = docker save; with the containerd store this is an OCI layout
tar xvf funbox.tar                                 # blobs/sha256/<digest>…  index.json  manifest.json  oci-layout
cat index.json | jq                                # → the index digest (8a01842…) + name annotations
cat manifest.json | jq                             # Docker's legacy list: Config blob + Layers for the saved platform
cat blobs/sha256/8a01842… | jq                     # the index: one manifest digest per platform (+ attestations)
cat blobs/sha256/e5ca9f9… | jq                     # the arm64 manifest: config digest + 5 layer digests in order
cat blobs/sha256/e4475d4… | jq                     # the config: Env, Cmd, User, history, rootfs.diff_ids
file blobs/sha256/82312fc…                         # gzip compressed data — a layer tarball
sha256sum blobs/sha256/8a01842…                    # equals the filename: content-addressed
docker image load -i funbox.tar                    # = docker load; the reverse of save (air-gapped transfer)
```

### Layers in action — the writable layer

```bash
docker container run -d --name fb spurin/funbox sleep 3600
docker container exec fb sh -c 'echo hi > /tmp/out.txt; echo changed >> /etc/motd; rm -rf /examples'
docker container diff fb                           # A /tmp/out.txt   C /etc/motd   D /examples — the upperdir, listed
docker container inspect --format '{{json .GraphDriver.Data}}' fb | jq   # LowerDir / UpperDir / MergedDir (classic store, Linux)
docker container rm -f fb                          # the writable layer is gone with it — hence volumes
docker container run --rm spurin/funbox cat /etc/motd   # a fresh container sees the image's original: layers are immutable
```

## Namespaces and cgroups — looking under the hood (Linux host)

```bash
# Namespaces
lsns                                                  # all namespaces on the host and the PID owning each
ls -l /proc/$$/ns/                                    # your shell's: cgroup ipc mnt net pid user uts time
sudo unshare --pid --fork --mount-proc bash           # new PID namespace: inside, ps shows you as PID 1
docker run -d --name web nginx
docker inspect --format '{{.State.Pid}}' web          # the container's PID as the HOST sees it
sudo ls -l /proc/$(docker inspect -f '{{.State.Pid}}' web)/ns/   # its namespaces (different inode numbers from yours)
sudo nsenter -t $(docker inspect -f '{{.State.Pid}}' web) -n ip addr   # step into its network namespace
docker exec web hostname                              # UTS namespace: hostname == container ID
docker exec web ps aux                                # PID namespace: nginx is PID 1

# cgroups
cat /proc/self/cgroup                                 # which cgroup your shell belongs to
cat /sys/fs/cgroup/cgroup.controllers                 # controllers available (cgroups v2)
docker run -d --name limited --memory=256m --cpus=0.5 nginx   # Docker writes these into a cgroup
docker stats --no-stream limited                      # cgroup accounting: CPU %, memory usage / limit
cat /sys/fs/cgroup/system.slice/docker-$(docker inspect -f '{{.Id}}' limited).scope/memory.max   # 268435456

# Clean up
docker rm -f web limited
```

On Docker Desktop the namespace/cgroup files live inside the VM; use `docker run --rm -it --privileged --pid=host alpine nsenter -t 1 -m -u -n -i sh` to get a shell in that VM first.
