# Solution — Level 1 (instructor reference)

> Keep out of player hands. Reference path + root cause for grading and the report.

## Intended path
1. `docker compose up --build` brings up `vulnerable`, `patched`, `webapp`, `attacker`.
2. The `vulnerable` entrypoint loops a request carrying
   `session=<LAB_TOKEN>&user=<LAB_USER>&pass=<LAB_PASS>` into the 1.0.1f
   `s_server`, so those strings stay resident in heap buffers.
3. Attacker runs `python3 heartbleedExploit.py vulnerable`:
   - sends a ClientHello advertising the heartbeat extension,
   - sends a heartbeat request claiming a 0x4000-byte payload while supplying
     almost none (the CVE-2014-0160 bounds-check miss),
   - reads back up to ~64 KB of server memory and prints it as a raw
     hex + ASCII dump (no extraction — the player analyses it).
4. Player spots `user=<LAB_USER>&pass=<LAB_PASS>` in the ASCII column of the
   dump, signs in at <http://localhost:8090>, and the dashboard renders
   `LAB_FLAG`. The credentials are not in every over-read, so this usually
   takes a few runs — that models real Heartbleed heap analysis.

## Root cause / what it teaches
`tls1_process_heartbeat` trusts the attacker-supplied `payload` length and
`memcpy`s that many bytes out of the record buffer without checking it against
the bytes actually received. The extra bytes are adjacent heap memory —
here, the replayed credentials. This is the baseline Heartbleed read primitive
that every later attack level builds on.

## Verifying the flag
The real flag is `LAB_FLAG` in the gitignored `shared/secrets.env`. The portal
serves exactly that value on the dashboard after a correct login, and
`./ctf.sh submit attack-01 <flag>` compares the submission to it. Because the
flag is only reachable through a valid login, a correct flag proves the player
leaked and used working credentials.
