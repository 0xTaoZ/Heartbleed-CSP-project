# Solution — Level 3 (instructor reference)

> Keep out of player hands. Reference path + root cause for grading and the report.

## Intended path
1. `docker compose up --build` brings up `vulnerable`, `patched`, `webapp`, `attacker`.
2. The `vulnerable` entrypoint loops a request carrying
   `session=<LAB_TOKEN>&user=<LAB_USER>&pass=<LAB_PASS>&keypem=...` into the
   1.0.1f `s_server`, so the session token stays resident in heap buffers. The
   token is the SAME `LAB_TOKEN` both containers read from `shared/secrets.env`.
3. At startup the `webapp` pre-seeds `ACTIVE_SESSIONS[LAB_TOKEN] =
   {"user": "cfo@securecorp.lab", "flag": LAB_FLAG_L3}` — a victim who is
   already signed in. There is no form password that authenticates the CFO, so
   the login form cannot produce this session; only the stolen token can.
4. Attacker runs `python3 heartbleedExploit.py vulnerable` and finds
   `session=<LAB_TOKEN>` (32 hex chars) in the ASCII column of the over-read.
   As with level 1, it isn't in every dump, so this usually takes a few runs.
5. Player replays the token with no login:
   ```bash
   curl -s http://localhost:8090/dashboard -H 'Cookie: session=<LAB_TOKEN>'
   ```
   The portal matches the cookie against `ACTIVE_SESSIONS`, renders
   "Welcome, cfo@securecorp.lab", and prints `LAB_FLAG_L3`.

## Root cause / what it teaches
Same Heartbleed read primitive as level 1 (`tls1_process_heartbeat` over-reads
adjacent heap) — but the leaked value is a **bearer session token**, not a
credential. The lesson is the difference:
- A session token is proof that authentication **already happened**, so replaying
  it **bypasses the login form, the password, and any second factor (2FA)**.
- The victim is a different, higher-value account than the level-1 login, and one
  with no reusable password here — so credential theft could never reach it, but
  a leaked live session owns it outright.
- Tokens are bearer secrets: possession == identity. This is why TLS memory
  disclosure is catastrophic even when passwords are strong or rotated.

## Verifying the flag
The real flag is `LAB_FLAG_L3` in the gitignored `shared/secrets.env`. The portal
serves exactly that value on the victim's dashboard, reachable only by presenting
the seeded session token, and `./ctf.sh submit attack-03 <flag>` compares the
submission to it. A correct flag proves the player leaked and replayed the live
session rather than logging in.

## Notes for the instructor
- This level needs **no change** to `vulnerable/entrypoint.sh`: it already plants
  `session=<LAB_TOKEN>`. The only wiring is the webapp pre-seed.
- The token here is **static** (does not rotate), so it is always replayable once
  leaked. A harder variant could rotate the victim token periodically (webapp
  writes the current token to the shared `labshare` volume; the entrypoint plants
  whatever is current) to force the player to catch a *live* session before it
  expires — deferred to keep this level reliable.
