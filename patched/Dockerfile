# syntax=docker/dockerfile:1

# patched: OpenSSL 1.0.1g, the Heartbleed fix. This is the control.
# 打补丁的服务器:用修好的 OpenSSL 1.0.1g,作为对照组。
# Same as vulnerable/, only one version newer.  和 vulnerable/ 一样,只是版本高一级。

# ---- build stage ----  构建阶段
FROM debian:bullseye-slim AS builder

# Debian 11 is end-of-life, use the archive mirror.  Debian 11 已停维护,用存档源。
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

# Download the 1.0.1g source, fall back to a mirror.  下载 1.0.1g 源码,主地址不行用备用。
RUN set -eux; \
    gh="https://github.com/openssl/openssl/releases/download/OpenSSL_1_0_1g/openssl-1.0.1g.tar.gz"; \
    mirror="https://openssl-library.org/source/old/1.0.1/openssl-1.0.1g.tar.gz"; \
    wget -q -O openssl.tar.gz "$gh" || wget -q -O openssl.tar.gz "$mirror"; \
    tar xzf openssl.tar.gz; \
    rm openssl.tar.gz

WORKDIR /usr/src/openssl-1.0.1g

# Same flags as vulnerable/. 1.0.1g keeps heartbeats but checks the length = the fix.
# 和 vulnerable/ 相同的参数。1.0.1g 保留心跳但会检查长度,这就是修复。
RUN set -eux; \
    ./config no-asm shared -fPIC -fcommon \
      --prefix=/opt/openssl-1.0.1g --openssldir=/opt/openssl-1.0.1g; \
    make -j1; \
    make install_sw

# ---- run stage ----  运行阶段
FROM debian:bullseye-slim

COPY --from=builder /opt/openssl-1.0.1g /opt/openssl-1.0.1g

# Make every call use this (patched) OpenSSL.  让程序用这份打了补丁的 OpenSSL。
ENV LD_LIBRARY_PATH=/opt/openssl-1.0.1g/lib

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 4433
ENTRYPOINT ["/entrypoint.sh"]
