# syntax=docker/dockerfile:1

# attacker: a minimal Python 3 box for the Heartbleed client (added later).
# 攻击机:跑 Heartbleed 客户端用的极简 Python 3 环境(脚本以后再加)。
# It does not get the secrets on purpose.  故意不给它秘密。
FROM python:3.12-slim

WORKDIR /app

# Standard library only, no third-party packages.  只用标准库,没有第三方包。
COPY requirements.txt ./

CMD ["python3", "-c", "print('attacker container ready; exploit scripts go in attacker/')"]
