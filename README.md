# Heartbleed CSP — Reproducing and Analyzing CVE-2014-0160

A reproducible lab for the course *CSP – Solving Current Challenges in Application Security*
(Hochschule Bonn-Rhein-Sieg). We reproduce the Heartbleed vulnerability in an isolated
Docker environment, analyze its root cause, and explore automated detection.

## Research question

How does the Heartbleed vulnerability arise from insufficient bounds checking in OpenSSL's
TLS heartbeat implementation, how can it be reproduced in an isolated and repeatable
environment, and to what extent can modern memory-safety testing techniques detect this
class of vulnerability?

## Repository structure

```
heartbleed-csp/
├── README.md              # this file
├── docker-compose.yml     # wires the three containers on one isolated network
├── vulnerable/            # OpenSSL 1.0.1f + minimal TLS server (the bug is here)
│   └── Dockerfile
├── patched/               # OpenSSL 1.0.1g + minimal TLS server (fixed)
│   └── Dockerfile
├── attacker/              # Heartbleed test client (standard public PoC)
│   └── README.md
├── webapp/                # Secure Corp login portal (the CTF objective)
├── ctf.sh                 # CTF game controller (list levels, briefs, grade flags)
├── levels/                # one self-contained folder per CTF level
│   ├── README.md          # progression map (4 attack + several defense levels)
│   ├── _template/         # copy this to add a level
│   └── attack-01-credentials/
├── detection/
│   ├── asan/              # minimal C example built with AddressSanitizer
│   └── fuzzing/           # simplified heartbeat parser + fuzzer
├── results/               # captured outputs, logs, screenshots
└── report-notes/          # notes for the written report
```

## How to reproduce

> Work in progress — commands will be added as the lab is built.

```bash
docker compose build
docker compose up
```

## Playing the CTF

The lab is structured as a capture-the-flag game. Each challenge lives in its own
folder under `levels/` and is driven by the `ctf.sh` controller:

```bash
./ctf.sh levels                     # list all levels and their status
./ctf.sh brief  attack-01           # read a level's objective + hints
./ctf.sh submit attack-01 'CTF_FLAG{...}'   # grade your flag
```

Level 1 (`attack-01`): leak the portal's login credentials from the vulnerable
TLS server with Heartbleed, then sign in at <http://localhost:8090> to reveal the
flag. See [`levels/README.md`](levels/README.md) for the full progression and how
to add new levels.

Then run the tests (to be documented) and compare the vulnerable vs patched behaviour.

## Safety / ethics

All containers communicate only over an internal Docker network and expose nothing to the
public internet. We never target real systems or real data: a harmless marker string is
planted in the test server's memory to demonstrate the over-read.

## References

OpenSSL security advisory, CVE-2014-0160 (NVD), and the OpenSSL 1.0.1f → 1.0.1g source diff.
Full citations are kept in the report.
