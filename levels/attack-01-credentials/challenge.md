# Level 1 — Leak the employee portal login credentials

**Category:** attack · **Points:** 100 · **Target:** `vulnerable` (OpenSSL 1.0.1f, port 4433)

## Scenario
Secure Corp runs an internal employee portal. Logging in loads secret session
tokens and a flag into the server's memory. The portal itself looks solid — but
the company also runs an old TLS service on the same network, built on a version
of OpenSSL from early 2014. That service never stops talking to itself, and its
memory is full of things it shouldn't hand out.

## Your objective
Recover a valid **username and password** for the portal by reading memory out of
the vulnerable TLS server with Heartbleed (CVE-2014-0160). Then use those
credentials to sign in to the portal and reveal the flag.

## What you're given
- `vulnerable` — OpenSSL 1.0.1f TLS server on `vulnerable:4433`. It keeps
  replaying the login credentials into its own heap, so they're sitting in
  memory waiting to leak.
- `attacker` — a container with a ready Heartbleed client:
  `attacker/heartbleedExploit.py`. It sends the malformed heartbeat and prints the
  raw over-read as a hex + ASCII dump. It does **not** extract anything for you —
  reading the leaked memory and finding the credentials is the challenge.
- `webapp` — the portal, published on your host at <http://localhost:8090>.

## Steps
```bash
# 1. bring the lab up
docker compose up --build

# 2. from the attacker container, leak memory from the vulnerable server
docker compose exec attacker python3 heartbleedExploit.py vulnerable
#    you get a raw hex + ASCII dump; scan the ASCII column for user=.../pass=...
#    run it a few times — the credentials aren't in every over-read

# 3. sign in at http://localhost:8090 with the leaked username + password
#    the dashboard prints the flag
```

## Hints
<details><summary>Hint 1</summary>The flag is <b>not</b> in the TLS server's memory. Only the login credentials are. The flag lives behind the portal login.</details>
<details><summary>Hint 2</summary>One heartbeat over-read returns ~64 KB of whatever happens to be on the heap. If the credentials aren't in this dump, run the exploit again.</details>
<details><summary>Hint 3</summary>The leaked strings look like <code>user=...</code> and <code>pass=...</code>. Those are the portal's Email and Password fields.</details>

## Submitting
```bash
./ctf.sh submit attack-01 'CTF_FLAG{...}'
```
