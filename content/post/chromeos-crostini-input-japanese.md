+++
slug = ""
tags = ["chromeos"]
title = "ChromeOSのLinuxで日本語入力する（2022年版）"
date = "2022-10-18T23:57:14+09:00"
+++

久しぶりにアップデートしたら日本語入力ができなくなってしまったのでメモ。

<!--more-->

## 環境

``` shell
$ cat /etc/debian_version
11.5
```

## これまでの設定方法

これまでの方法は調べるといくつも見つかる。例えばこれ
[ChromebookのLinux環境(日本語)セットアップ](https://3nmt.com/chromebook_linux_japanese/)

この状態で日本語入力ができていたのだが、Debianを上記のバージョンにアップデートしたところ、GUIで日本語入力ができなくなった。
調べたところ、`cros-garcon.service`で環境変数を設定する方法はDeprecatedになったらしい。

``` shell
$ cat /etc/systemd/user/cros-garcon.service.d/cros-garcon-override.conf
# This file has been deprecated and could be removed in the future.
# Environment variables in the container can be set session-wide by systemd.
# See environment.d(5) or the following URL for more information:
# https://chromium.googlesource.com/chromiumos/docs/+/main/containers_and_vms.md#Can-I-set-environment-variables-for-my-container
```

自分はデフォルトで存在する上記のファイルではなく、別のファイルを作成して環境変数を設定していた。
もし上記のファイルを変更していた場合はDebianをアップデートしても上記のコメントは挿入されないかもしれない。

``` shell
$ cat /etc/systemd/user/cros-garcon.service.d/99-fcitx.conf
Environment="GTK_IM_MODULE=fcitx"
Environment="QT_IM_MODULE=fcitx"
Environment="XMODIFIERS=@im=fcitx"
```

## 新しい設定方法

代わりの方法は上のファイルに書かれている通り、`man 5 environment.d`を確認してみる。
どうやら設定ファイルに1行ずつ`KEY=VALUE`形式で書いてやればよさそう。
使えるファイル名はいくつかあるが、`/etc/environment.d/99-fcitx.conf`に書く。たぶんこのディレクトリがベスト。
読み込み順はファイル名でソートされる（後のものが優先）ため、適当に数字をつけておく。

``` shell
$ cat <<EOF | sudo tee /etc/environment.d/99-fcitx.conf
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
EOF
```

これでLinuxを再起動（不要かも）をすれば反映される。
