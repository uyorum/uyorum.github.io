+++
slug = ""
tags = ["epgstation", "linux", "systemd", "shellscript"]
title = "EPGStationの録画データをNASへ自動で同期する"
date = "2023-09-23T23:22:31+09:00"
+++

EPGStation上に置いたままだと何かと取り回しづらいのでNASへ同期するようにしました。

<!--more-->

以下のような設計、コンセプトで実装します。

* NASのプロトコルはNFSを使う（EPGStation側に追加のソフトウェアを入れたくなかったため）
    * NFSはroot squashを有効にする
* EPGStationからはautofsを用いて自動マウント・アンマウントを設定する（不要なときはNAS側のディスクを止めたいため）
* 同期はrsyncを使ってmp4のみコピーする。m2tsはコピーしない
* ffmpegでエンコード中のmp4はコピーしない

EPGStation側の設定は以前[この記事](../raspberrypi-mirakurun-epgstation/)でまとめています。

なお、機種によるのでNAS側の設定は省略します。

## autofsの設定

/mnt/nas/recordedにマウントするようにします。  
マウントポイントのディレクトリは自動で作成してくれるので自分で作る必要はありません。

``` shell
$ sudo apt install -y autofs
$ echo '/mnt/nas /etc/auto-nas.misc' | sudo tee /etc/auto.master.d/nas.autofs
$ echo 'recorded -fstype=nfs,rw,async,defaults NAS-IP:/shared/path' | sudo tee /etc/auto-nas.misc
$ sudo systemctl enable autofs
$ sudo systemctl restart autofs
```

autofsで使用する設定ファイルは2種類あり、

* autofsで制御するマウントポイントとその設定を定義するファイル（/etc/auto.master.d以下に作成する）
* 上で定義したマウントポイント以下のフォルダに何をマウントするのか定義するファイル（ファイルパスは上のファイルで指定する）

今回は`/mnt/nas/recorded`にNASの`/shared/path`をマウントしています。
restartで反映させたあとにこのディレクトリにアクセスすると自動でマウントされることがわかります。

ちなみにアンマウントまでの時間はデフォルトでは5分のようです。

/etc/autofs.conf

``` shell
# timeout - set the default mount timeout in seconds. The internal
#           program default is 10 minutes, but the default installed
#           configuration overrides this and sets the timeout to 5
#           minutes to be consistent with earlier autofs releases.
#
timeout = 300
```

### 参考

[8.3. autofs Red Hat Enterprise Linux 7 | Red Hat Customer Portal](https://access.redhat.com/documentation/ja-jp/red_hat_enterprise_linux/7/html/storage_administration_guide/nfs-autofs#s2-nfs-config-autofs)

## rsyncコマンドの精査

今回一番悩んだポイントはffmpegでエンコード中のmp4はコピーしないようにすること。  
方法はいろいろ考えましたがrsync単体ではできなさそうなのでスクリプトにすることにしました。  
`ps`でffmpegプロセスを探してその出力先のファイルをrsyncの`exclude`オプションに渡すことにします。  
スクリプトはこんな感じ。

``` bash
#!/bin/bash

readonly RECORD_ROOT=/app/recorded/
readonly RSYNC_FROM=/mnt/recorded/
readonly RSYNC_DEST=/mnt/nas/recorded

# Access to mount-point to mount NAS
test -d ${RSYNC_DEST}

# `RSYNC_FROM`からの相対パスに変換
# rsyncにそのまま渡すために[と]をエスケープする
encoding_files=$(ps aux | grep [f]fmpeg | awk '{ print $NF }' | sed -e "s#${RECORD_ROOT}##g" -e 's#\([].[]\)#\\\1#g')

excludes=""
for file in ${encoding_files}; do
  excludes="${excludes} --exclude=${file}"
done

# root_squashでマウントしているため`-a`オプションは使えない（所有者と所有グループを保持できない）
# r: サブディレクトリ内も対象にする
# l: シンボリックリンクもそのまま転送する
# t: 更新時刻を保持する
# O: ディレクトリはtオプションの対象外とする（後述）
# u: 上書きするかどうかを更新時刻で判定する
# prune-empty-dirs: 空ディレクトリは転送しない
rsync -rltuOvn ${excludes} --include='*/' --include='*.mp4' --exclude='*' --prune-empty-dirs ${RSYNC_FROM} ${RSYNC_DEST}
```

* EPGStationをDockerで稼働させているため、ffmpegに渡している出力先フォルダはコンテナ内のもの（`RECORD_ROOT`）でありホストから見たパス（`RSYNC_FROM`）と異なります
* `grep`に渡している`[f]fmpeg`はgrepプロセス自身が出てこないようにするテクニックです
* manによるとrsyncの`-a`オプションは`-rlptgoD`と同等のようなので`root_squash`環境では実現できない`-pgoD`を除きました

rsyncの`O`オプションなしで実行したところ以下のエラーが発生したので`O`オプションを追加しました。宛先の最上位ディレクトリの更新時刻を変更しようとして失敗しているようです。
一応そのままでも転送はできましたが気になったのでエラーが出ないようにします。

> rsync: [generator] failed to set times on "/mnt/nas/recorded/.": Operation not permitted (1)

### 参考

* [UNIX/rsync/指定した拡張子のファイルだけ同期する - yanor.net/wiki](https://yanor.net/wiki/?UNIX/rsync/%E6%8C%87%E5%AE%9A%E3%81%97%E3%81%9F%E6%8B%A1%E5%BC%B5%E5%AD%90%E3%81%AE%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB%E3%81%A0%E3%81%91%E5%90%8C%E6%9C%9F%E3%81%99%E3%82%8B)
* [rsyncでエラーが出たけどコピーはできてる - ごずろぐ](https://gozuk16.hatenablog.com/entry/2014/09/30/224900)

## 定期実行

あとはこのスクリプトを適当なパスに置いて定期的に実行するようにします。  
すでに大量の録画データがある場合は初回稼働は手で実行したほうがいいかも。

昔ながらの方法なら定期実行はcronで設定することですが、今回はせっかくなのでSystemdのtimerで行うことにしました。

/etc/systemd/system/sync-to-nas.service

``` ini
[Unit]
Description=Sync recorded movies to NAS

[Service]
User=pi
Type=oneshot
ExecStart=/usr/local/bin/sync-to-nas.sh
RemainAfterExit=no
```

/etc/systemd/system/sync-to-nas.timer

``` ini
[Unit]
Description=Sync recorded movies to NAS

[Timer]
OnCalendar=*-*-* 6:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

毎日6:00に実行するようにしました。
本当はもっと頻繁に実行したいところですが、差分がなくても毎回NASへのアクセスが発生してNASのディスクが起動してしまうのでやめました。

ファイルを作成したらSystemdを再読み込みして反映させます。

``` shell
$ sudo systemctl daemon-reload
$ sudo systemctl enable --now sync-to-nas.timer
$ sudo systemctl status sync-to-nas.timer
● sync-to-nas.timer - Sync recorded movies to NAS
     Loaded: loaded (/etc/systemd/system/sync-to-nas.timer; enabled; vendor preset: enabled)
     Active: active (waiting) since Sat 2023-09-23 23:14:51 JST; 12min ago
    Trigger: Sun 2023-09-24 06:00:00 JST; 6h left
   Triggers: ● sync-to-nas.service
```

以上

{{< affiliate asin="B07JGYV4Q8" title="［改訂第3版］シェルスクリプト基本リファレンス ──#!/bin/shで、ここまでできる" >}}
