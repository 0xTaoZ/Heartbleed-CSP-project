#!/bin/sh
# Start the vulnerable TLS server and keep the fake secrets in its memory.
set -eu

OPENSSL=/opt/openssl-1.0.1f/bin/openssl
PORT=4433
CERT=/tmp/cert.pem
KEY=/tmp/key.pem
PUB=/tmp/pub.pem
# Shared with the webapp so the portal can publish the encrypted level-2 flag.
SHARE=/share
ENC="$SHARE/flag2.enc"

# If a command is given (e.g. `openssl version`), just run it and stop.
if [ "$#" -gt 0 ]; then
  exec "$@"
fi

# Secrets come from shared/secrets.env; fail early if missing.
: "${LAB_USER:?LAB_USER not set}"
: "${LAB_PASS:?LAB_PASS not set}"
: "${LAB_TOKEN:?LAB_TOKEN not set}"
: "${LAB_FLAG_L2:?LAB_FLAG_L2 not set}"
# LAB_FLAG (level 1) is intentionally not used here: the level-1 flag must not
# live in this server's memory — only the leakable material does (login
# credentials, the session token, and the TLS private key).

# Self-signed cert + RSA private key. This KEY is the level-2 objective: it is
# kept resident in the server's heap (below) so a Heartbleed over-read leaks it.
"$OPENSSL" req -x509 -newkey rsa:2048 -nodes -days 365 \
  -keyout "$KEY" -out "$CERT" -subj "/CN=vulnerable.lab" >/dev/null 2>&1

# Encrypt the level-2 flag to THIS boot's public key and publish the ciphertext.
# The ciphertext is public (served by the portal at /flag2.enc); only the leaked
# private key can decrypt it. Recovering the key == decrypting the flag.
mkdir -p "$SHARE"
"$OPENSSL" x509 -in "$CERT" -pubkey -noout > "$PUB" 2>/dev/null
printf '%s' "$LAB_FLAG_L2" \
  | "$OPENSSL" pkeyutl -encrypt -pubin -inkey "$PUB" -out "$ENC" 2>/dev/null
echo "[*] Level-2 flag encrypted to this server's public key -> $ENC (served at /flag2.enc)"

# Put the PEM on a single line so the replay loop can plant it with the same
# proven GET primitive as the credentials (a multi-line body needs a POST, which
# wedges the single-threaded s_server). Newlines -> '~', spaces -> '_', so the
# request line stays valid (no spaces) and the key is still greppable in memory
# as -----BEGIN_PRIVATE_KEY-----~...  The player reverses it with `tr '~_' '\n '`.
KEYLINE=$(tr '\n ' '~_' < "$KEY")
# The Heartbleed over-read starts a fixed offset into the request buffer, so the
# first bytes of whatever we plant are always lost. Prepend throwaway padding so
# that lost head falls in the padding and the whole key is captured intact.
PAD=$(printf 'P%.0s' $(seq 1 256))

# TLS server on port 4433.
"$OPENSSL" s_server -accept "$PORT" -cert "$CERT" -key "$KEY" -WWW &
SERVER_PID=$!

cleanup() { kill "$SERVER_PID" 2>/dev/null || true; }
trap cleanup INT TERM

sleep 1

# Plant ALL the secrets in ONE padded request so a single over-read leaks them
# together: the login credentials (level 1), the TLS private key (level 2), and
# the victim's live session token (level 3, the session= field). A separate small
# request gets overwritten in the heap by the big key request, so it would rarely
# leak; keeping them in one request fixes that.
# The GET primitive is answered by -WWW and then closed, so s_client exits
# cleanly and the single-threaded server is never wedged. The leading pad absorbs
# the fixed head-loss of the over-read; the credentials sit right after it, the
# key after those.
i=0
while kill -0 "$SERVER_PID" 2>/dev/null; do
  printf 'GET /?pad=%s&user=%s&pass=%s&session=%s&keypem=%s HTTP/1.0\r\n\r\n' \
    "$PAD" "$LAB_USER" "$LAB_PASS" "$LAB_TOKEN" "$KEYLINE" \
    | "$OPENSSL" s_client -quiet -connect localhost:"$PORT" >/dev/null 2>&1 || true
  i=$((i + 1))
  [ "$i" -ge 3 ] && { i=0; sleep 1; }
done

wait "$SERVER_PID"
