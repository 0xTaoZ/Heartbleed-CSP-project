#!/bin/sh
# Start the vulnerable TLS server and keep the fake secrets in its memory.
set -eu

OPENSSL=/opt/openssl-1.0.1f/bin/openssl
PORT=4433
CERT=/tmp/cert.pem
KEY=/tmp/key.pem

# If a command is given (e.g. `openssl version`), just run it and stop.
if [ "$#" -gt 0 ]; then
  exec "$@"
fi

# Secrets come from shared/secrets.env; fail early if missing.
: "${LAB_USER:?LAB_USER not set}"
: "${LAB_PASS:?LAB_PASS not set}"
: "${LAB_TOKEN:?LAB_TOKEN not set}"
# LAB_FLAG is intentionally not used here: the flag must not live in this
# server's memory, so a Heartbleed leak can only expose the login credentials.

# Self-signed cert (not part of the bug).
"$OPENSSL" req -x509 -newkey rsa:2048 -nodes -days 365 \
  -keyout "$KEY" -out "$CERT" -subj "/CN=vulnerable.lab" >/dev/null 2>&1

# TLS server on port 4433.
"$OPENSSL" s_server -accept "$PORT" -cert "$CERT" -key "$KEY" -WWW &
SERVER_PID=$!

cleanup() { kill "$SERVER_PID" 2>/dev/null || true; }
trap cleanup INT TERM

sleep 1

# Keep sending the login credentials so they stay in the server's memory.
# The flag is deliberately excluded: a Heartbleed leak should expose the
# credentials, not the flag (the flag lives only behind the portal login).
while kill -0 "$SERVER_PID" 2>/dev/null; do
  printf 'GET /?session=%s&user=%s&pass=%s HTTP/1.0\r\n\r\n' \
    "$LAB_TOKEN" "$LAB_USER" "$LAB_PASS" \
    | "$OPENSSL" s_client -quiet -connect localhost:"$PORT" >/dev/null 2>&1 || true
  sleep 2
done

wait "$SERVER_PID"
