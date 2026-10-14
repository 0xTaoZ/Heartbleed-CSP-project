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

Then run the tests (to be documented) and compare the vulnerable vs patched behaviour.

## Safety / ethics

All containers communicate only over an internal Docker network and expose nothing to the
public internet. We never target real systems or real data: a harmless marker string is
planted in the test server's memory to demonstrate the over-read.

## References

OpenSSL security advisory, CVE-2014-0160 (NVD), and the OpenSSL 1.0.1f → 1.0.1g source diff.
Full citations are kept in the report.
