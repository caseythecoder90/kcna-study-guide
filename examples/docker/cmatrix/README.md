# cmatrix — building a container image from source

Companion to [03-06 Building Container Images](../../../notes/03-containers-with-docker/06-building-container-images.md). Two Dockerfiles for the same program so the optimisation can be measured rather than believed:

| File | What it is |
|---|---|
| [`Dockerfile.single-stage`](Dockerfile.single-stage) | The interactive `history` transcript turned into a Dockerfile, with `RUN cd` replaced by `WORKDIR`. Works; ships the whole toolchain |
| [`Dockerfile`](Dockerfile) | The final form: multi-stage, one `RUN` per stage, `COPY --from`, runtime deps only, non-root `USER`, `ENTRYPOINT` + `CMD` |

No bind mounts, no host paths — the source is cloned inside the build — so this runs the same from PowerShell, cmd, WSL, macOS or Linux.

```bash
docker build -f Dockerfile.single-stage -t cmatrix:single-stage .
docker build -t cmatrix .

docker image ls cmatrix                       # compare SIZE: hundreds of MB vs ~10 MB
docker image history cmatrix:single-stage     # 14 layers, the 200+ MB one is alpine-sdk
docker image history cmatrix                  # a handful; nothing from the build stage survives
docker image inspect -f '{{json .Config.Labels}}' cmatrix | jq
docker image inspect -f '{{.Config.User}} {{json .Config.Entrypoint}} {{json .Config.Cmd}}' cmatrix   # thomas ["./cmatrix"] ["-b"]

docker run --rm -it cmatrix                   # ./cmatrix -b — Ctrl-C or q to quit
docker run --rm -it cmatrix -ab               # arguments replace CMD, ENTRYPOINT stays
docker run --rm -it --entrypoint sh cmatrix   # look around as user thomas: whoami; ls -l /cmatrix
docker run --rm -it cmatrix:single-stage      # same program, fat image, running as root
```

Multi-platform build and push (needs a Docker Hub account; replace the namespace):

```bash
docker buildx create --name multi --use --driver docker-container
docker buildx build --platform linux/amd64,linux/arm64 -t caseythecoder90/cmatrix:1.0.0 --push .
docker buildx imagetools inspect caseythecoder90/cmatrix:1.0.0      # one manifest per platform
```

On a machine without QEMU handlers registered (some Linux hosts), first run `docker run --privileged --rm tonistiigi/binfmt --install all`. Docker Desktop has them built in.

Things to try:

- Break it on purpose: put `RUN cd cmatrix/` back in place of `WORKDIR` and read the error from `autoreconf`.
- Delete the `COPY --from` line and run the image — the "nothing to run" failure of version 3.
- Delete `ncurses-terminfo-base` and run it — the runtime-data failure static linking doesn't cover.
- Add a `.dockerignore` and a stray large file in this directory; watch the build context size in the first line of `docker build` output.
