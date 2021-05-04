+++
slug = ""
tags = []
title = "WSL2にPodmanを入れる"
date = "2021-04-14T21:55:17+09:00"
aliases = ["/blog/podman-on-wsl2/"]

+++

最近は仕事でPodmanを触る機会が多いので自宅のWSLにもDockerではなくPodmanを入れることにする。

<!--more-->

[How to run Podman on Windows with WSL2 | Enable Sysadmin](https://www.redhat.com/sysadmin/podman-windows-wsl2)  
基本的にはこの記事どおりなのだが一部この記事の通りではいかない箇所があった。


## Podmanインストール

``` shell
$ . /etc/os-release
$ sudo sh -c "echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/x${NAME}_${VERSION_ID}/ /' > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list"
$ wget -nv https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/x${NAME}_${VERSION_ID}/Release.key -O Release.key
$ sudo apt-key add - < Release.key
$ sudo apt-get update -qq
$ sudo apt-get -qq -y install podman
$ sudo mkdir -p /etc/containers
$ echo -e "[registries.search]\nregistries = ['docker.io', 'quay.io']" | sudo tee /etc/containers/registries.conf
```

これでPodmanコマンドは使えるようになる

``` shell
$ podman info
host:
  arch: amd64
  buildahVersion: 1.19.4
  cgroupManager: cgroupfs
  cgroupVersion: v1
  conmon:
    package: 'conmon: /usr/libexec/podman/conmon'
    path: /usr/libexec/podman/conmon
    version: 'conmon version 2.0.27, commit: '
    ..
```

ただし、WSL2環境ではPodmanコマンドの度に以下のオプションを指定するよう書かれている

```
--cgroup-manager cgroupfs --event-logger file
```

いちいちオプションを追加するのは面倒なので設定ファイルで設定することにする。

ちなみに確認した限りではそのままだと以下のエラーが出る。`cgroup_manager`の必要性はよくわからない。

``` shell
$ podman run -it --rm centos:7 bash                                                                                                                          [~]
ERRO[0000] unable to write pod event: "write unixgram @00037->/run/systemd/journal/socket: sendmsg: no such file or directory"
ERRO[0000] unable to write pod event: "write unixgram @00037->/run/systemd/journal/socket: sendmsg: no such file or directory"
ERRO[0000] unable to write pod event: "write unixgram @00037->/run/systemd/journal/socket: sendmsg: no such file or directory"
ERRO[0000] unable to write pod event: "write unixgram @00037->/run/systemd/journal/socket: sendmsg: no such file or directory"
[root@9697f94b4a75 /]#
```

## Rootlessコンテナ用

podmanコマンドの設定ファイルで`--event-logger file`の部分を設定すればよい。
デフォルトでは設定ファイルは存在しない（記事中には`podman info`などを実行すれば生成されるとあるが自分の環境では生成されなかった）ので自分で作成する。
また記事中ではファイル名は`libpod.conf`となっているが、`containers.conf`でよい。

この設定ファイルはtableとoptionという階層構造になっている。
`man containers.conf`からそれらしい項目を探すと、「engine」tableの「events_logger="file"」でよいことがわかる。

``` shell
$ mkdir -p $HOME/.config/containers
$ cat <<'EOF' >$HOME/.config/containers/containers.conf
[engine]
events_logger="file"
EOF
```

## Rootfulコンテナ用

同様に探すと`cgroup_manager`も`engine`tableにある。

``` shell
$ cat <<'EOF' | sudo tee /etc/containers/containers.conf
[engine]
cgroup_manager="cgroupfs"
events_logger="file"
EOF
```

## 確認

以上でコンテナが起動できるようになる。

``` shell
$ podman run -it --rm centos:7 bash                                                                                                                          [~]
[root@8f869401da0f /]#
```

以上
