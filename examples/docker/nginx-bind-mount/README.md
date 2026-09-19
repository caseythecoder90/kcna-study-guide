# nginx with a bind-mounted page

Companion to [03-05 Container Networking and Volumes](../../../notes/03-containers-with-docker/05-networking-and-volumes.md). Serves `index.html` from this directory through the stock `nginx` image, without editing anything inside the container: the file is **bind-mounted** over `/usr/share/nginx/html/index.html`, read-only, and port 80 in the container is **published** on host port 12345.

Run from this directory.

```bash
# Linux / macOS / WSL
docker run -d --rm --name golden-hour -p 12345:80 \
  -v "$(pwd)/index.html:/usr/share/nginx/html/index.html:ro" nginx
```

```powershell
# Windows PowerShell — quote the argument; ${PWD} gives the absolute path -v requires
docker run -d --rm --name golden-hour -p 12345:80 -v "${PWD}\index.html:/usr/share/nginx/html/index.html:ro" nginx
```

```bat
:: Windows cmd
docker run -d --rm --name golden-hour -p 12345:80 -v "%cd%\index.html:/usr/share/nginx/html/index.html:ro" nginx
```

Then open http://localhost:12345. Edit `index.html` on the host, refresh — no restart needed. Explore:

```bash
docker container port golden-hour            # 80/tcp -> 0.0.0.0:12345
docker container inspect -f '{{json .Mounts}}' golden-hour | jq   # Type: bind, Source, Destination, RW: false
docker container exec golden-hour ls /usr/share/nginx/html        # 50x.html and index.html — only index.html is yours
docker container exec golden-hour sh -c 'echo x > /usr/share/nginx/html/index.html'   # fails: read-only
docker container stop golden-hour            # --rm removes it; index.html stays here, untouched
```

Variants worth trying:

- Mount the **directory** instead of the file (`-v "$(pwd):/usr/share/nginx/html:ro"`) and note that nginx's own `50x.html` disappears from the container's view — a bind mount hides the image's directory contents.
- Replace `-p 12345:80` with `-P` and find the random host port with `docker container port golden-hour`.
- Same page via a **named volume** to see pre-population: `docker volume create web && docker run --rm -v web:/usr/share/nginx/html nginx ls /usr/share/nginx/html` (the image's files were copied into the empty volume).

`index.html` is a self-contained animated page (no external assets), so it works offline and is a clear visual signal that the mount took effect.
