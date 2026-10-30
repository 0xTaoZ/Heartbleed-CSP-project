# Heartbleed-Labor ausführen

Einfache Schritte, um die drei Container zu bauen und zu starten.

## Voraussetzungen

- Docker (dieses Projekt nutzt colima).
- Auf einem Apple-Silicon-Mac muss colima Rosetta aktiviert haben (`vmType: vz`,
  `rosetta: true`), damit die amd64-Images gebaut werden können.

## 1. Secrets-Datei anlegen (nur beim ersten Mal)

Die Server lesen die Test-Secrets aus `shared/secrets.env`. Diese Datei liegt
nicht in Git, also legst du sie einmal an. Aus der Vorlage kopieren:

```sh
cp shared/secrets.env.example shared/secrets.env
```

Oder Zufallswerte erzeugen:

```sh
rand() { head -c "$1" /dev/urandom | od -An -tx1 | tr -d ' \n'; }
printf 'LAB_USER=admin\nLAB_PASS=S3cr3t-%s\nLAB_TOKEN=%s\nLAB_FLAG=CTF_FLAG{%s}\n' \
  "$(rand 4)" "$(rand 16)" "$(rand 8)" > shared/secrets.env
```

## 2. Images bauen

```sh
docker compose build
```

Der erste Build dauert länger (OpenSSL wird aus dem Quellcode kompiliert).
Spätere Builds nutzen den Cache und sind schnell.

## 3. Versionen prüfen

```sh
docker compose run --rm vulnerable /opt/openssl-1.0.1f/bin/openssl version
docker compose run --rm patched    /opt/openssl-1.0.1g/bin/openssl version
```

Erwartete Ausgabe:

- `OpenSSL 1.0.1f 6 Jan 2014` (vulnerable)
- `OpenSSL 1.0.1g 7 Apr 2014` (patched)

## 4. Labor starten

```sh
docker compose up -d
docker compose ps
```

`vulnerable` und `patched` sollten `Up` sein. `attacker` gibt eine Meldung aus
und beendet sich (vorerst nur ein Platzhalter).

## 5. Prüfen, dass die Server lauschen

```sh
docker compose logs vulnerable
docker compose logs patched
```

Suche die Zeile `ACCEPT`. Sie bedeutet, dass der TLS-Server auf Port 4433
lauscht.

## 6. Labor stoppen

```sh
docker compose down
```

## Hinweise

- `labnet` ist ein internes Netzwerk; die Server sind nicht zum Host veröffentlicht.
- `shared/secrets.env` wird von Git ignoriert.
