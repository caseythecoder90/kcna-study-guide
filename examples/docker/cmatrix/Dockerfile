# cmatrix — final form from notes/03-containers-with-docker/06-building-container-images.md
#
#   docker build -t cmatrix .
#   docker run --rm -it cmatrix            # ./cmatrix -b  (ENTRYPOINT + default CMD)
#   docker run --rm -it cmatrix -ab        # ./cmatrix -ab (CMD replaced by the arguments)
#
# Pin the base (alpine:3.x or @sha256:…) in anything that matters; left floating here to match the course.

# ---- Stage 1: build — has the toolchain, is thrown away ----
FROM alpine AS cmatrixbuilder

WORKDIR /cmatrix

# One RUN = one layer. Index refresh and install in the same instruction so the cache can't go stale.
RUN apk update --no-cache && \
    apk add git autoconf automake alpine-sdk ncurses-dev ncurses-static && \
    git clone https://github.com/spurin/cmatrix.git . && \
    autoreconf -i && \
    mkdir -p /usr/lib/kbd/consolefonts /usr/share/consolefonts && \
    ./configure LDFLAGS="-static" && \
    make

# ---- Stage 2: runtime — only what the binary needs ----
FROM alpine

LABEL org.opencontainers.image.authors="Casey Quinn" \
      org.opencontainers.image.description="Container image from the matrix - check it out at https://github.com/abishekvashok/cmatrix" \
      org.opencontainers.image.source="https://github.com/spurin/cmatrix"

# terminfo is data ncurses reads at runtime — static linking bundles code, not files.
# adduser: -g display name, -s no login shell, -D no password, -H no home directory.
RUN apk update --no-cache && \
    apk add ncurses-terminfo-base && \
    adduser -g "Thomas Anderson" -s /usr/sbin/nologin -D -H thomas

COPY --from=cmatrixbuilder /cmatrix/cmatrix /cmatrix

USER thomas
ENTRYPOINT ["./cmatrix"]
CMD ["-b"]
