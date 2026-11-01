# syntax=docker/dockerfile:1

# vulnerable: OpenSSL 1.0.1f, the Heartbleed bug (CVE-2014-0160) is left in on purpose.
# Lab only, internal network, amd64 (Rosetta on Apple Silicon).

# ---- build stage: compile OpenSSL from source ----
FROM debian:bullseye-slim AS builder

# Debian 11 is end-of-life, so use the archive mirror for the build tools.
RUN set -eux; \
    printf '%s\n' \
      'deb http://archive.debian.org/debian bullseye main' \
      'deb http://archive.debian.org/debian-security bullseye-security main' \
      > /etc/apt/sources.list; \
    apt-get -o Acquire::Check-Valid-Until=false update; \
    apt-get install -y --no-install-recommends \
      build-essential wget ca-certificates perl make; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src

# Download the 1.0.1f source, fall back to a mirror.
RUN set -eux; \
    gh="https://github.com/openssl/openssl/releases/download/OpenSSL_1_0_1f/openssl-1.0.1f.tar.gz"; \
    mirror="https://openssl-library.org/source/old/1.0.1/openssl-1.0.1f.tar.gz"; \
    wget -q -O openssl.tar.gz "$gh" || wget -q -O openssl.tar.gz "$mirror"; \
    tar xzf openssl.tar.gz; \
    rm openssl.tar.gz

WORKDIR /usr/src/openssl-1.0.1f

# -fcommon: let this old code link on new gcc.
# no-asm: use C crypto, avoids asm trouble under emulation.
# Heartbeats stay ON (no -DOPENSSL_NO_HEARTBEATS) = keep the bug.
RUN set -eux; \
    ./config no-asm shared -fPIC -fcommon \
      --prefix=/opt/openssl-1.0.1f --openssldir=/opt/openssl-1.0.1f; \
    make -j1; \
    make install_sw

# ---- run stage: only the built OpenSSL, no build tools ----
FROM debian:bullseye-slim

COPY --from=builder /opt/openssl-1.0.1f /opt/openssl-1.0.1f

# Make every call use this (vulnerable) OpenSSL.
ENV LD_LIBRARY_PATH=/opt/openssl-1.0.1f/lib

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 4433
ENTRYPOINT ["/entrypoint.sh"]
