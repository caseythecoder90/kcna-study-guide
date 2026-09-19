# Docker — command reference

The Docker commands to know for daily use and for the certification labs (KCNA questions, the CKA/CKS runtime tasks), organised by the noun they act on. Every entry shows the management form `docker <noun> <verb>` (Docker 1.13+) with the traditional alias where one exists; they are the same command. Placeholders: `C` = container name or ID (a unique prefix of the ID is enough), `IMG` = image reference.

Chapter-specific lab blocks from Section 3 are at the end.

## Getting oriented

```bash
docker version                     # client + server versions; the server is the daemon (inside the Desktop VM on Win/Mac)
docker info                        # runtime (containerd/runc), storage driver, cgroup driver/version, kernel, resources
docker --help ; docker image --help ; docker container run --help   # the CLI documents itself; --help works at every level
docker system df                   # disk used by images, containers, volumes, build cache
docker system prune                # remove stopped containers, unused networks, dangling images, build cache (-a: all unused images; --volumes too)
docker events                      # live stream of daemon events (create, start, die, ...)
docker context ls                  # which daemon the CLI is talking to (desktop-linux, default, remote hosts)
```

## Images — `docker image …`

```bash
docker image pull IMG                     # docker pull   — defaults: registry docker.io, namespace library/, tag :latest
docker image pull IMG@sha256:<digest>     #                 immutable pull by content hash
docker image ls [--digests] [-a] [-q]     # docker images — list; -a includes intermediate layers; -q IDs only
docker image inspect IMG                  # JSON: Config (Env, Cmd, Entrypoint, ExposedPorts), RootFS.Layers, RepoDigests
docker image history IMG                  # instruction per row; which created layers vs 0 B metadata
docker image tag SRC DST                  # docker tag    — another name for the same image
docker image push IMG                     # docker push   — to the registry in the name; prints the digest
docker image rm IMG                       # docker rmi    — -f if containers still reference it
docker image prune [-a]                   # dangling images / all unused images
docker image save IMG -o f.tar            # docker save   — export (OCI layout with the containerd store)
docker image load -i f.tar                # docker load   — import
docker image build -t NAME:TAG .          # docker build  — from ./Dockerfile; -f other.Dockerfile; --no-cache; --platform linux/amd64
docker buildx imagetools inspect IMG      # registry-side index: digest + one manifest per platform (--raw for the JSON)
docker login [REGISTRY] ; docker logout   # credentials in the credential store, never in images
docker search TERM                        # Docker Hub search
```

## Containers — `docker container …`

### Create and run

```bash
docker container run IMG [CMD]            # docker run = create + start; CMD after the image replaces the image's CMD
docker container run -d IMG               # detached (background), prints the ID
docker container run -it IMG sh           # interactive shell: -i keep STDIN open, -t allocate a TTY
docker container run --rm IMG             # delete the container when it exits
docker container run --name web IMG       # a name you choose (also the DNS name on user-defined networks)
docker container run -p 8080:80 IMG       # publish host 8080 → container 80  (-p 127.0.0.1:8080:80 to bind locally; /udp)
docker container run -P IMG               # publish every EXPOSEd port to a random high host port
docker container run -e KEY=VAL --env-file .env IMG   # environment variables
docker container run -v NAME:/path IMG    # named volume (created if missing)
docker container run -v /host/dir:/path[:ro] IMG      # bind mount (absolute host path)
docker container run --mount type=volume,src=NAME,dst=/path IMG   # the explicit form; type=bind|volume|tmpfs
docker container run -w /app -u 1000:1000 IMG         # working dir, non-root user
docker container run --network NET IMG    # attach to a network (bridge default; host, none, or a user-defined one)
docker container run --memory 256m --cpus 0.5 IMG     # cgroup limits
docker container run --restart unless-stopped IMG     # no | on-failure[:N] | always | unless-stopped
docker container run --entrypoint sh IMG  # override ENTRYPOINT
docker container create IMG               # docker create — everything run does except starting it
```

### Lifecycle

```bash
docker container ls                       # docker ps     — running only
docker container ls -a                    # docker ps -a  — all states: created restarting running removing paused exited dead
docker container ls -q ; -l ; --filter status=exited ; --format '{{.Names}} {{.Status}}'
docker container start C                  # docker start  — a created or exited container (-a attach, -i interactive)
docker container stop C                   # docker stop   — SIGTERM, 10 s grace (-t N), then SIGKILL
docker container kill C                   # docker kill   — SIGKILL now (-s SIGHUP to send another signal)
docker container restart C                # docker restart
docker container pause C / unpause C      # freeze / thaw via the cgroup freezer
docker container rm C                     # docker rm     — a stopped container; -f to stop-and-remove; -v also its anonymous volumes
docker container prune                    # remove all stopped containers
docker container rename C NEW
docker container update --memory 512m C   # change cgroup limits and restart policy on a live container
docker container wait C                   # block until it exits, print the exit code
```

### Inspect and interact

```bash
docker container exec -it C sh            # docker exec   — run an extra process inside (the way to get a shell)
docker container exec C cat /etc/hostname #                 one-off command, no shell
docker container exec -u root -w /tmp C ls
docker container attach C                 # attach the terminal to PID 1 (detach with Ctrl-P Ctrl-Q; Ctrl-C may stop it)
docker container logs C                   # docker logs   — PID 1's stdout/stderr; -f follow, --tail 100, --since 10m, -t timestamps
docker container inspect C                # JSON: State, Config, Mounts, NetworkSettings.IPAddress, HostConfig
docker container inspect -f '{{.State.Status}} {{.NetworkSettings.IPAddress}}' C
docker container top C                    # processes inside, as the host sees them
docker container stats [C]                # live cgroup usage; --no-stream for one sample
docker container port C                   # published port mappings
docker container diff C                   # files Added/Changed/Deleted in the writable layer
docker container cp C:/path/in ./out ; docker container cp ./in C:/path   # copy files out / in (works on stopped containers)
docker container commit C NEWIMG          # snapshot the writable layer into a new image — demo use only; build from a Dockerfile instead
docker container export C -o rootfs.tar   # flatten the filesystem to a tar (no layers, no metadata; contrast: image save)
```

## Networks — `docker network …`

```bash
docker network ls                         # bridge (default), host, none, plus user-defined networks
docker network create NET                 # user-defined bridge: containers on it resolve each other by name
docker network create -d overlay NET      # multi-host (Swarm); other drivers: macvlan, ipvlan
docker network inspect NET                # subnet, gateway, attached containers and their IPs
docker network connect NET C / disconnect NET C   # attach/detach a running container
docker network rm NET ; docker network prune
docker container run --network host IMG   # share the host's network namespace (no port mapping needed; Linux only)
docker container run --network none IMG   # loopback only
```

## Volumes — `docker volume …`

```bash
docker volume create NAME
docker volume ls
docker volume inspect NAME                # Mountpoint: /var/lib/docker/volumes/NAME/_data (inside the VM on Win/Mac)
docker volume rm NAME
docker volume prune                       # unused volumes (data is lost)
docker container run -v NAME:/data IMG    # attach; an empty new volume is pre-populated with the image's /data contents
```

## Build — Dockerfile essentials

```bash
docker image build -t app:1.0 .           # context = current dir; .dockerignore trims it
docker image build --target builder .     # stop at a stage of a multi-stage build
docker image build --platform linux/amd64,linux/arm64 -t app:1.0 --push .   # multi-arch via buildx
```

Instructions that create layers: `FROM`, `RUN`, `COPY`, `ADD`. Metadata only: `ENV`, `CMD`, `ENTRYPOINT`, `USER`, `WORKDIR`, `EXPOSE`, `LABEL`, `ARG`, `STOPSIGNAL`, `HEALTHCHECK`, `VOLUME`. `EXPOSE` documents a port and is what `-P` publishes; it does not open anything by itself.

## Compose — `docker compose …`

```bash
docker compose up -d                      # from compose.yaml in the current dir; builds if needed
docker compose ps ; logs -f ; exec svc sh
docker compose down [-v]                  # stop and remove containers, networks (-v: volumes too)
```

## Cross-platform notes (this repo is developed on Windows)

- Paths in `-v` must be absolute. PowerShell: `-v "${PWD}\dir:/path"`; cmd: `-v %cd%\dir:/path`; WSL/Git Bash: `-v /mnt/c/Users/…:/path` or `$(pwd)`. Quote the argument in PowerShell.
- Git Bash rewrites `/path` arguments into Windows paths; prefix with `MSYS_NO_PATHCONV=1` or use `//path`.
- PowerShell 5.1 pipes to native commands re-encode bytes: for `| sha256sum`-style checks, redirect via `cmd /c` and hash the file, or use WSL.
- On Docker Desktop, `/var/lib/docker` and volume mountpoints are inside the hidden VM; reach them with `docker run --rm -it --privileged --pid=host alpine nsenter -t 1 -m -u -n -i sh`.

---

## Section 3 lab blocks

### 03-01 — the shared kernel

```bash
docker run ubuntu uname -a ; docker run amazonlinux uname -a ; docker run centos uname -a   # same kernel every time
docker run ubuntu cat /etc/os-release                                                       # userspace differs
```

### 03-02 — first interactive container

```bash
docker run -it ubuntu bash        # bash becomes PID 1
apt update && apt install -y htop ; htop     # bash = PID 1, htop its child; CPU/mem shown are the VM's
exit                              # PID 1 exits → container stops; docker ps -a shows Exited
```

### 03-03 — images, digests, the writable layer

```bash
docker image pull docker.io/spurin/funbox:latest          # five "Pull complete" lines = five layers, 3 concurrent by default
docker buildx imagetools inspect spurin/funbox --raw | sha256sum   # == the Digest from the pull (Linux; macOS: shasum -a 256)
mkdir /tmp/funbox && cd /tmp/funbox && docker image save spurin/funbox -o funbox.tar && tar xvf funbox.tar
cat index.json | jq ; cat manifest.json | jq ; cat blobs/sha256/<index-digest> | jq ; sha256sum blobs/sha256/<index-digest>
docker container run -d --name fb spurin/funbox sleep 3600
docker container exec fb sh -c 'echo hi > /tmp/out.txt; rm -rf /examples' && docker container diff fb   # A /tmp/out.txt  D /examples
docker container rm -f fb                                 # writable layer gone; the image is untouched
```

### 03-05 — ports, networks, mounts

```bash
docker run -d --name web nginx && docker container port web        # nothing published: unreachable from the host
docker run -d --rm -P -p 12345:80 nginx                            # -p host:container; -P every EXPOSEd port to a random host port
docker container port <C> ; docker ps                              # see the mappings
docker network ls ; docker network inspect bridge                  # default bridge: docker0, 172.17.0.0/16, no DNS
docker network create app-net && docker run -d --name db --network app-net redis && docker run --rm --network app-net redis redis-cli -h db ping   # name resolves

# the wrong way: edit inside the container (writable layer only)
docker exec -it <C> sh -c 'echo hello > /usr/share/nginx/html/index.html' ; docker container diff <C>

# the right way: bind mount (from examples/docker/nginx-bind-mount)
docker run -d --rm -p 12345:80 -v "$(pwd)/index.html:/usr/share/nginx/html/index.html:ro" nginx          # bash/WSL
docker run -d --rm -p 12345:80 -v "${PWD}\index.html:/usr/share/nginx/html/index.html:ro" nginx           # PowerShell
docker run -d --rm -p 12345:80 --mount type=bind,src="$(pwd)",dst=/usr/share/nginx/html,readonly nginx   # --mount form, whole directory

# named volumes: lifecycle independent of containers
docker volume create pgdata && docker run -d --name db -v pgdata:/var/lib/postgresql/data -e POSTGRES_PASSWORD=x postgres:16
docker rm -f db && docker volume ls                                # the volume is still there
docker volume inspect pgdata                                       # Mountpoint under /var/lib/docker/volumes/
```

### Namespaces and cgroups under the hood (Linux host)

```bash
lsns ; ls -l /proc/$$/ns/
sudo unshare --pid --fork --mount-proc bash               # new PID namespace: you are PID 1
docker inspect -f '{{.State.Pid}}' C                      # the container's PID on the host
sudo nsenter -t <pid> -n ip addr                          # enter its network namespace
docker run -d --memory=256m --cpus=0.5 nginx && docker stats --no-stream   # cgroup limits and accounting
cat /sys/fs/cgroup/cgroup.controllers                     # cgroups v2 controllers
```
