#!/bin/sh
# Start the patched TLS server (the control). Same setup as vulnerable/.
# 启动打补丁的 TLS 服务器(对照组),设置和 vulnerable/ 一样。
set -eu

OPENSSL=/opt/openssl-1.0.1g/bin/openssl
PORT=4433
CERT=/tmp/cert.pem
KEY=/tmp/key.pem

# If a command is given (e.g. `openssl version`), run it and stop.
# 带了命令(比如查版本)就直接执行然后退出。
if [ "$#" -gt 0 ]; then
  exec "$@"
fi

# Same secrets as vulnerable/: they sit in memory, but 1.0.1g won't leak them.
# 和 vulnerable/ 一样的秘密:它们在内存里,但 1.0.1g 不会漏出去。
: "${LAB_USER:?LAB_USER not set}"
: "${LAB_PASS:?LAB_PASS not set}"
: "${LAB_TOKEN:?LAB_TOKEN not set}"
: "${LAB_FLAG:?LAB_FLAG not set}"

# Self-signed cert (not part of the bug).  自签证书(和漏洞无关)。
"$OPENSSL" req -x509 -newkey rsa:2048 -nodes -days 365 \
  -keyout "$KEY" -out "$CERT" -subj "/CN=patched.lab" >/dev/null 2>&1

# TLS server on port 4433.  在 4433 端口开 TLS 服务。
"$OPENSSL" s_server -accept "$PORT" -cert "$CERT" -key "$KEY" -WWW &
SERVER_PID=$!

cleanup() { kill "$SERVER_PID" 2>/dev/null || true; }
trap cleanup INT TERM

sleep 1

# Same seeder loop as vulnerable/, so only the OpenSSL version differs.
# 和 vulnerable/ 相同的喂数据循环,保证只有 OpenSSL 版本不同。
while kill -0 "$SERVER_PID" 2>/dev/null; do
  printf 'GET /?user=%s&pass=%s&token=%s&flag=%s HTTP/1.0\r\n\r\n' \
    "$LAB_USER" "$LAB_PASS" "$LAB_TOKEN" "$LAB_FLAG" \
    | "$OPENSSL" s_client -quiet -connect localhost:"$PORT" >/dev/null 2>&1 || true
  sleep 2
done

wait "$SERVER_PID"
