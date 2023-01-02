+++
slug = ""
tags = []
title = "Raspberry PiにDockerでMirakurun/EPGStationを導入する"
date = "2023-01-02T16:46:36+09:00"
+++

ずっとやろうと思っていたところ新年に時間が取れたので一気にやっつけた。
それほど目新しいものはないが自分用のメモを兼ねてまとめておく。

<!--more-->

## ハードウェア

ハードウェア自体は前から持っていたので新たに購入したものはない。

* Raspbery Pi 4B (RAM4GB版)
* [地デジチューナー PX-S1UD](https://amzn.to/3Gyy7L6)
* 適当なMicroSDカード (32GB)
* 適当な外付けHDD

## 構築の流れ

### Raspberry Pi OSを導入

[公式サイト](https://www.raspberrypi.com/software/operating-systems/)からイメージをダウンロードする。  
GUIは不要なのでRaspberry Pi OS Lite、メモリは4GBしかないので32bitを選択した。

メモリ8GBの場合は64bitを選択した方がいいが、64bitの場合は後ほど導入するハードウェアエンコードの設定方法が異なるようなので注意。

ディスプレイなしでセットアップするためイメージを焼いたあとにいくつか設定しておく。

* SSHサーバを有効化  
    デフォルトではSSHサーバが有効になっていないため
    bootパーティション直下に`ssh`という空のファイルを作成する
* ユーザを作成  
    過去のRaspberry Pi OSではpiというユーザがデフォルトで作成されていたが、最近はそれがなくなったらしい。  
    ひとまず昔と同じようにpiユーザを作成する。方法はbootパーティション直下に`userconf.txt`を作成してユーザ名とパスワード（のハッシュ）を格納しておく。

    参照：[Raspberry Pi Documentation - Configuration](https://www.raspberrypi.com/documentation/computers/configuration.html#configuring-a-user)

    いったん弱いパスワードで設定したがあとでパスワードは無効化するため問題ない。

``` shell
$ touch /boot/ssh
$ echo pi:$(echo password | openssl passwd -6 -stdin) >/boot/userconf.txt
```

### OS設定

以上の内容でSDカードをセットアップしたらSSHでログインできる状態でOSが起動してくる。
SSHでログインできるようになったら以下の設定を入れていく

#### アップデート

``` shell
$ sudo rpi-update
$ sudo apt update
$ sudo apt upgrade
```

#### raspi-config

``` shell
$ sudo raspi-config
```

* ホスト名を設定
* VNCを無効化
* locale -> en_US.UTF-8に設定
* Timezone -> Asia/Tokyo
* Expand filesystem

いったんここでrebootしておく

#### パスワード無効化

`authorized_keys`に公開鍵を設定 (ssh-copy-idを使用)してから以下を実行

``` shell
$ sudo passwd -d pi
$ sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/g' /etc/ssh/sshd_config
$ sudo systemctl restart ssh
```

#### スワップを無効化  

SDカードの書き込みを減らすために設定

``` shell
$ sudo swapoff --all
$ sudo systemctl stop dphys-swapfile
$ sudo systemctl disable dphys-swapfile
```

#### 時刻同期

``` shell
$ sudo apt install -y chrony
$ sudo vi /etc/chrony/chrony.conf
// pool行を「pool time.google.com iburst」に変更
$ sudo systemctl restart chrony
```

#### Bluetoothを無効化  

少しでも消費電力を少なくするために設定しておく

``` shell
$ cat <<EOF | sudo tee -a /boot/config.txt

# Disable Bluetooth
dtoverlay=disable-bt
EOF
$ sudo systemctl disable hciuart.service
$ sudo systemctl disable bluealsa.service
$ sudo systemctl disable bluetooth.service
```

#### WiFi無効化

``` shell
$ sudo iwconfig wlan0 txpower off
```

#### ハードウェアエンコード有効化

``` shell
$ echo 'SUBSYSTEM=="vchiq",GROUP="video",MODE="0666"' | sudo tee /etc/udev/rules.d/10-vchiq-permissions.rules
```

#### 外付けHDDをマウント

``` shell
$ sudo apt install xfsprogs
$ sudo fdisk /dev/sda
// sda1を作成
$ sudo mkfs.xfs /dev/sda1
$ sudo mkdir /mnt/recorded
$ echo '/dev/sda1 /mnt/recorded xfs defaults 0 0' | sudo tee -a /etc/fstab
$ sudo mount -a
$ sudo chmod 777 /mnt/recorded
```

最後にパーミッションを777にしているのはEPGStationコンテナ内のプロセス(ffmpeg)から書き込みできるようにするため。  
ネットではEPGStationのUIDを1000にするのがよく見つかるが、UIDを固定するのがしっくりこなかったため自分はこのようにした。

このあたりで一度rebootしておく。

### チューナードライバをインストール

メジャーなチューナーなので方法は検索すればすぐ見つかる。

``` shell
$ wget http://plex-net.co.jp/plex/px-s1ud/PX-S1UD_driver_Ver.1.0.1.zip
$ unzip PX-S1UD_driver_Ver.1.0.1.zip
$ sudo cp PX-S1UD_driver_Ver.1.0.1/x64/amd64/isdbt_rio.inp /lib/firmware/
```

### カードリーダー

これは不要かもしれない

``` shell
$ sudo apt install pcscd pcsc-tools libccid
$ sudo pcsc_scan
```

最後に「Japanese Chijou Digital B-CAS Card (pay TV)」という文字列が表示される。
Ctrl-Cで終了。

### Docker

``` shell
$ curl -sSL https://get.docker.com/ | CHANNEL=stable sh
$ sudo usermod -aG docker $USER
```

最後の`usermod`はpiユーザでsudoなしで`docker`コマンドを実行できるようにするため。  
変更を反映させるためにSSHで再ログインしておく。

### Mirakurun/EPGStation

一式をDockerで動かすためのComposeファイルはすでに[公開されている](https://github.com/l3tnun/docker-mirakurun-epgstation)が、Raspberry Piではそのままでは動かないためいくつか変更する。

同様の試みをしている方もいたが、中身がやや古いので最新版をベースに自分でやり直した。  
[CH3COOH/docker-mirakurun-epgstation: Mirakurun + EPGStation on Docker](https://github.com/CH3COOH/docker-mirakurun-epgstation)

リポジトリはここで公開している。  
[uyorum/rpi-docker-mirakurun-epgstation: Mirakurun + EPGStation on Docker tuned for Raspberry Pi](https://github.com/uyorum/rpi-docker-mirakurun-epgstation)

``` shell
$ curl -sf https://raw.githubusercontent.com/uyorum/rpi-docker-mirakurun-epgstation/v2/setup.sh | sh -s
$ cd rpi-docker-mirakurun-epgstation
```

`mirakurun/conf/channels.yml`と`docker-compose.yml`を適宜編集する。
自分の場合、録画データは外付けHDDをマウントした`/mnt/recorded`に保存したかったので`docker-compose.yml`を以下のように変更した。

``` diff
@@ -52,7 +52,7 @@ services:
             - ./epgstation/data:/app/data
             - ./epgstation/thumbnail:/app/thumbnail
             - ./epgstation/logs:/app/logs
-            - ./recorded:/app/recorded
+            - /mnt/recorded:/app/recorded
             - /opt/vc/lib:/opt/vc/lib:ro
         environment:
             TZ: "Asia/Tokyo"
```

編集が終わったら以下のコマンドでコンテナを起動する。初回はイメージのビルドとともにffmpegをビルドするので数十分かかる。

``` shell
$ docker compose up -d
```

コンテナが無事起動したらチャンネルスキャンを実行しておく。

``` shell
$ curl -X PUT "http://localhost:40772/api/config/channels/scan"
```

これで`http://IP:8888`にアクセスすればEPGStationのWebUIが表示される。

以上

{{< affiliate asin="B081YD3VL5" title="【国内正規代理店品】Raspberry Pi4 ModelB 4GB ラズベリーパイ4 技適対応品【RS・OKdo版】" >}}

## 参考

* [uyorum/rpi-docker-mirakurun-epgstation: Mirakurun + EPGStation on Docker tuned for Raspberry Pi](https://github.com/uyorum/rpi-docker-mirakurun-epgstation)
* [Raspberry Pi 4とdocker-mirakurun-epgstationで録画サーバーを構築する (2021年4月版) - 酢ろぐ！](https://blog.ch3cooh.jp/entry/2021/04/06/200732#%E3%83%A9%E3%82%BA%E3%83%91%E3%82%A4%E3%81%AE%E8%A8%AD%E5%AE%9A%E3%83%8F%E3%83%BC%E3%83%89%E3%82%A6%E3%82%A7%E3%82%A2%E3%82%A8%E3%83%B3%E3%82%B3%E3%83%BC%E3%83%89%E3%81%AE%E6%9C%89%E5%8A%B9%E5%8C%96)
* [【ラズパイ】テレビ録画サーバーの設定 - 車輪日記](https://bowmiow.net/garage/raspi-tv2/#toc2)
