# syntax=docker/dockerfile:1

# attacker: a minimal Python 3 box for the Heartbleed client (added later).
# It does not get the secrets on purpose.
FROM python:3.12-slim

WORKDIR /app

# Standard library only, no third-party packages.
COPY requirements.txt ./

CMD ["python3", "-c", "print('attacker container ready; exploit scripts go in attacker/')"]
