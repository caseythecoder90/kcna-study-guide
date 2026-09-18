# Local lab setup — commands

Docker Desktop plus its built-in Kubernetes is enough for every lab in the course. Companion to [`../03-containers-with-docker/02-docker-setup-and-install.md`](../03-containers-with-docker/02-docker-setup-and-install.md).

## Docker Desktop

Install from https://docs.docker.com/desktop/ (Windows: WSL 2 backend recommended; macOS: pick the Apple silicon or Intel build). Then:

```bash
docker version            # Client and Server sections — Server = the engine inside the hidden VM
docker info               # runtime (containerd/runc), cgroup driver and version, OS/kernel of the VM, resources
docker run --rm hello-world
```

Settings worth knowing: **Resources** (CPU, memory, swap, disk for the VM — on Windows/WSL 2 use `%UserProfile%\.wslconfig` instead), **Kubernetes** (enable; choose kubeadm single-node or kind multi-node), **Extensions**.

## Kubernetes in Docker Desktop

```bash
kubectl config get-contexts               # docker-desktop is added when Kubernetes is enabled
kubectl config use-context docker-desktop
kubectl get nodes                         # docker-desktop  Ready  control-plane
kubectl get nodes -o wide                 # container runtime: containerd, kernel: linuxkit
kubectl cluster-info
kubectl get pods -A                       # the control plane runs as Pods in kube-system
```

Reset from *Settings → Kubernetes → Reset Kubernetes cluster* when a lab leaves it in a mess.

## Docker Engine on Linux (no VM)

```bash
curl -fsSL https://get.docker.com | sh            # convenience script; or the distro package
sudo usermod -aG docker $USER && newgrp docker    # run docker without sudo
docker info | grep -iE 'kernel|cgroup|runtime'    # host kernel (3.10+ required), cgroup v1/v2, runc
```
