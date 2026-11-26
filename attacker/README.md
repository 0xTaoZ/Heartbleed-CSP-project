# attacker

A minimal Python 3 container for the Heartbleed (CVE-2014-0160) client that will
target the lab's own `vulnerable` and `patched` servers on the internal network.

`heartbleedExploit.py` sends the malformed heartbeat and prints the raw
over-read as a hex + ASCII dump. It deliberately does **not** parse or extract
anything: reading the leaked memory and finding the credentials is the player's
job (level 1). The container does not get `shared/secrets.env`, so secrets have
to be recovered from leaked memory, not read directly.

```bash
docker compose exec attacker python3 heartbleedExploit.py vulnerable
```

Lab use only.
