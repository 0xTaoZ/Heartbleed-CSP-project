# 如何运行 Heartbleed 实验靶场

构建并运行三个容器的简单步骤。

## 需要什么

- Docker(本项目用 colima)。
- 苹果芯片的 Mac:colima 需开启 Rosetta(`vmType: vz`、`rosetta: true`),才能构建 amd64 镜像。

## 1. 生成密钥文件(只需一次)

服务器从 `shared/secrets.env` 读取假密钥。这个文件不进 git,所以要自己建一次。从示例复制:

```sh
cp shared/secrets.env.example shared/secrets.env
```

或生成随机值:

```sh
rand() { head -c "$1" /dev/urandom | od -An -tx1 | tr -d ' \n'; }
printf 'LAB_USER=admin\nLAB_PASS=S3cr3t-%s\nLAB_TOKEN=%s\nLAB_FLAG=CTF_FLAG{%s}\n' \
  "$(rand 4)" "$(rand 16)" "$(rand 8)" > shared/secrets.env
```

## 2. 构建镜像

```sh
docker compose build
```

第一次构建较慢(要从源码编译 OpenSSL)。之后走缓存,很快。

## 3. 检查版本

```sh
docker compose run --rm vulnerable /opt/openssl-1.0.1f/bin/openssl version
docker compose run --rm patched    /opt/openssl-1.0.1g/bin/openssl version
```

预期输出:

- `OpenSSL 1.0.1f 6 Jan 2014`(vulnerable)
- `OpenSSL 1.0.1g 7 Apr 2014`(patched)

## 4. 运行靶场

```sh
docker compose up -d
docker compose ps
```

`vulnerable` 和 `patched` 应为 `Up`。`attacker` 打印一句话后退出(目前只是占位)。

## 5. 查看服务器在监听

```sh
docker compose logs vulnerable
docker compose logs patched
```

找到 `ACCEPT` 那一行,表示 TLS 服务器在 4433 端口监听。

## 6. 停止靶场

```sh
docker compose down
```

## 说明

- `labnet` 是内部网络,服务器不对宿主机开放端口。
- `shared/secrets.env` 不进 git。
