# syntax=docker/dockerfile:1

# vulnerable: OpenSSL 1.0.1f, the Heartbleed bug (CVE-2014-0160) is left in on purpose.
# 有漏洞的服务器:故意用带 Heartbleed 漏洞的 OpenSSL 1.0.1f。
# Lab only, internal network, amd64 (Rosetta on Apple Silicon).
# 仅实验用,内部网络,amd64(苹果芯片走 Rosetta)。

# ---- build stage: compile OpenSSL from source ----  构建阶段:从源码编译 OpenSSL
FROM debian:bullseye-slim AS builder

# Debian 11 is end-of-life, so use the archive mirror for the build tools.
# Debian 11 已停止维护,改用存档源装编译工具。
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

# Download the 1.0.1f source, fall back to a mirror.  下载 1.0.1f 源码,主地址不行就用备用。
RUN set -eux; \
    gh="https://github.com/openssl/openssl/releases/download/OpenSSL_1_0_1f/openssl-1.0.1f.tar.gz"; \
    mirror="https://openssl-library.org/source/old/1.0.1/openssl-1.0.1f.tar.gz"; \
    wget -q -O openssl.tar.gz "$gh" || wget -q -O openssl.tar.gz "$mirror"; \
    tar xzf openssl.tar.gz; \
    rm openssl.tar.gz

WORKDIR /usr/src/openssl-1.0.1f

# -fcommon: let this old code link on new gcc.  让老代码在新 gcc 上能链接。
# no-asm: use C crypto, avoids asm trouble under emulation.  用 C 版加密,避免模拟器下汇编出问题。
# Heartbeats stay ON (no -DOPENSSL_NO_HEARTBEATS) = keep the bug.  保留心跳 = 保留漏洞。
RUN set -eux; \
    ./config no-asm shared -fPIC -fcommon \
      --prefix=/opt/openssl-1.0.1f --openssldir=/opt/openssl-1.0.1f; \
    make -j1; \
    make install_sw

# ---- run stage: only the built OpenSSL, no build tools ----  运行阶段:只放编好的 OpenSSL
FROM debian:bullseye-slim

COPY --from=builder /opt/openssl-1.0.1f /opt/openssl-1.0.1f

# Make every call use this (vulnerable) OpenSSL.  让程序用这份有漏洞的 OpenSSL。
ENV LD_LIBRARY_PATH=/opt/openssl-1.0.1f/lib

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 4433
ENTRYPOINT ["/entrypoint.sh"]
