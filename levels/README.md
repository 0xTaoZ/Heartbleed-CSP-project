# CTF levels

Each level is a self-contained folder under `levels/`. The game controller
`ctf.sh` (repo root) reads these folders — add a level by copying `_template/`,
nothing else needs to change.

## Anatomy of a level
```
levels/<category>-<nn>-<slug>/
├── level.env      # manifest: id, title, category, points, target, flag var, status
├── challenge.md   # player-facing brief (objective, hints, how to submit)
└── solution.md    # instructor-only reference path + root cause
```

Real flags never live in git. `level.env` only names the variable
(`LEVEL_FLAG_VAR`) that holds the flag inside the gitignored
`shared/secrets.env`; `ctf.sh submit` grades against that value.

## Controller
```bash
./ctf.sh levels              # list every level + status
./ctf.sh brief  attack-01    # print a level's challenge brief
./ctf.sh submit attack-01 F  # grade a flag submission
./ctf.sh solution attack-01  # instructor: print the reference solution
```

## Progression

### Attack (4 levels)
| # | id | objective | leaks from | status |
|---|----|-----------|-----------|--------|
| 1 | `attack-01` | Leak portal **login credentials**, sign in, read the flag | `vulnerable` heap | **ready** |
| 2 | `attack-02` | Steal the server's **TLS private key**, decrypt the portal's published secret | `vulnerable` heap | **ready** |
| 3 | `attack-03` | Hijack a victim's live **session token**, replay it to the dashboard (no login) | `vulnerable` heap | **ready** |
| 4 | `attack-04` | *TBD* (e.g. **heap grooming** to pull a specific secret reliably) | — | planned |

### Defense (several levels)
| id | objective | status |
|----|-----------|--------|
| `defense-01` | Swap in **patched** OpenSSL 1.0.1g and show the leak is gone | planned |
| `defense-02` | **Detect** the bug at build time (AddressSanitizer on the heartbeat parser) | planned |
| `defense-03` | **Fuzz** the heartbeat parser to find the over-read automatically | planned |

The attack levels escalate the *value* of what Heartbleed leaks (credentials →
key → live session → reliable extraction); the defense levels walk from
"patch it" to "catch it automatically". Level 4 and the defense specifics are
placeholders — lock them in as the lab grows.
