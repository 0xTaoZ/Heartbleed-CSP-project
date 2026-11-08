# How to run the Heartbleed lab

Simple steps to build and run the three containers.

## What you need

- Docker (this project uses colima).
- On an Apple Silicon Mac, colima must have Rosetta on (`vmType: vz`,
  `rosetta: true`) so the amd64 images can build.

## 1. Make the secrets file (first time only)

The servers read fake secrets from `shared/secrets.env`. This file is not in
git, so you make it once. Copy the example:

```sh
cp shared/secrets.env.example shared/secrets.env
```

Or make random values:

```sh
rand() { head -c "$1" /dev/urandom | od -An -tx1 | tr -d ' \n'; }
printf 'LAB_USER=admin\nLAB_PASS=S3cr3t-%s\nLAB_TOKEN=%s\nLAB_FLAG=CTF_FLAG{%s}\n' \
  "$(rand 4)" "$(rand 16)" "$(rand 8)" > shared/secrets.env
```

## 2. Build the images

```sh
docker compose build
```

The first build is slow because it compiles OpenSSL from source. Later builds
use the cache and are fast.

## 3. Check the versions

```sh
docker compose run --rm vulnerable /opt/openssl-1.0.1f/bin/openssl version
docker compose run --rm patched    /opt/openssl-1.0.1g/bin/openssl version
```

Expected output:

- `OpenSSL 1.0.1f 6 Jan 2014` (vulnerable)
- `OpenSSL 1.0.1g 7 Apr 2014` (patched)

## 4. Run the lab

```sh
docker compose up -d
docker compose ps
```

`vulnerable`, `patched`, and `webapp` should be `Up`. `attacker` runs the
Heartbleed attack against `vulnerable` and then exits.

## 5. See the servers listening

```sh
docker compose logs vulnerable
docker compose logs patched
```

Look for the `ACCEPT` line. It means the TLS server is listening on port 4433.

## 6. Stop the lab

```sh
docker compose down
```

## The CTF portal

A login portal runs at `http://localhost:8090` (the `webapp` service). It checks
logins against the same `LAB_USER` / `LAB_PASS` the vulnerable server keeps in
memory. Intended path: leak those credentials from `vulnerable` with the
Heartbleed attacker, then sign in to the portal to reveal the flag.

## Notes

- `labnet` is a bridged network so the portal is reachable from the host; the
  lab servers hold only fake secrets.
- `shared/secrets.env` is git-ignored.
