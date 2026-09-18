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
