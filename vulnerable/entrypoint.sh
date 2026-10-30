#!/bin/sh
# Start the vulnerable TLS server and keep the fake secrets in its memory.
# 启动有漏洞的 TLS 服务器,并把假秘密一直留在它的内存里。
set -eu

OPENSSL=/opt/openssl-1.0.1f/bin/openssl
PORT=4433
CERT=/tmp/cert.pem
KEY=/tmp/key.pem

# If a command is given (e.g. `openssl version`), just run it and stop.
# 如果带了命令(比如查版本),就直接执行然后退出。
if [ "$#" -gt 0 ]; then
  exec "$@"
fi

# Secrets come from shared/secrets.env; fail early if missing.
# 秘密来自 shared/secrets.env,缺了就直接报错。
: "${LAB_USER:?LAB_USER not set}"
: "${LAB_PASS:?LAB_PASS not set}"
: "${LAB_TOKEN:?LAB_TOKEN not set}"
: "${LAB_FLAG:?LAB_FLAG not set}"

# Self-signed cert (not part of the bug).  自签证书(和漏洞无关)。
"$OPENSSL" req -x509 -newkey rsa:2048 -nodes -days 365 \
  -keyout "$KEY" -out "$CERT" -subj "/CN=vulnerable.lab" >/dev/null 2>&1

# TLS server on port 4433.  在 4433 端口开 TLS 服务。
"$OPENSSL" s_server -accept "$PORT" -cert "$CERT" -key "$KEY" -WWW &
SERVER_PID=$!

cleanup() { kill "$SERVER_PID" 2>/dev/null || true; }
trap cleanup INT TERM

sleep 1

# Keep sending the secrets so they stay in the server's memory.
# 不停把秘密发进去,让它们一直待在服务器内存里。
while kill -0 "$SERVER_PID" 2>/dev/null; do
  printf 'GET /?user=%s&pass=%s&token=%s&flag=%s HTTP/1.0\r\n\r\n' \
    "$LAB_USER" "$LAB_PASS" "$LAB_TOKEN" "$LAB_FLAG" \
    | "$OPENSSL" s_client -quiet -connect localhost:"$PORT" >/dev/null 2>&1 || true
  sleep 2
done

wait "$SERVER_PID"
