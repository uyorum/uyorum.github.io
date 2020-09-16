+++
slug = ""
tags = []
title = "Raspberry Pi OS(Raspbian)にOctoPrintをインストールする"
date = "2020-09-16T20:36:56+09:00"

+++

[前回](../3d-printer-1/)、3Dプリンターを買って以降いろいろと調べている。
よく知らなかったが3Dプリンタは自作や改造ができたりするらしく、ちょうど開催されていた技術書典9で見つけた本を買ってみたところ
OctoPrintなるソフトウェアを使うことでネットワーク経由で印刷をすることができることがわかった。

<!--more-->

買ってみた同人誌はこちら
[Ender3で始める自宅3Dプリンタ：くろほん](https://techbookfest.org/product/5188169897082880?productVariantID=5724024109793280)

## 参考
[OctoPrint.org - Download &amp; Setup OctoPrint](https://octoprint.org/download/)  
[Setting up OctoPrint on a Raspberry Pi running Raspbian - OctoPrint Community Forum](https://community.octoprint.org/t/setting-up-octoprint-on-a-raspberry-pi-running-raspbian/2337)  
[raspberry pi zero wでOctoPrintを動かしてみた - Qiita](https://qiita.com/ysogabe/items/95b974d13b396cf7479e)  

## インストール方法
OctoPrintにはいくつかの導入方法が提供されている。

* OctoPi  
    RaspbianをベースにOctoPrintをセットアップ済みのイメージ。
    Raspberry Piがあれば、これをSDカードに焼くだけでインストールは終わる。
* 手動インストール  
    OctoPrintはPythonで書かれており、PyPIで配布されている。そのためPythonとpipを使って手動でインストールすることもできる。
    OctoPrintにはWebカメラなどを使って印刷の様子をブラウザで確認できる機能がある。そのような機能を使う場合はさらにffmpegのインストールなどを別途行う必要がある。

自分の場合、ちょうどRaspberry Pi 4Bが手元にあったが別の用途でも使用中のため、OctoPrint専用に使うわけにはいかなかった。
負荷的に同居でも問題なさそうなので、既存のRaspbianの上に手動でインストールを行うことにした。

### 環境

``` shell
$ lsb_release -a
No LSB modules are available.
Distributor ID: Raspbian
Description:    Raspbian GNU/Linux 10 (buster)
Release:        10
Codename:       buster
```

### 設計

* Pythonはaptで入る3系のものを使う
* OctoPrintはPythonの仮想環境にインストールし、システムを汚さないようにする
* 実行ユーザとして専用のユーザ「octoprint」を作成する
* サービスの起動はSystemdで行う

## 手順
### インストール

piユーザで実行

``` shell
$ sudo apt update
$ sudo apt install python3-pip python3-dev python3-setuptools python3-venv git libyaml-dev build-essential
$ sudo mkdir /usr/local/share/octoprint
$ sudo chown -R pi:pi /usr/local/share/octoprint
$ cd /usr/local/share/octoprint
$ python3 -m venv venv
$ source venv/bin/activate
$ pip install pip --upgrade
$ pip install octoprint
```

### ユーザの準備

``` shell
$ sudo useradd -r octoprint -d /usr/local/share/octoprint
$ sudo chown -R octoprint:octoprint /usr/local/share/octoprint
$ sudo usermod -a -G tty octoprint
$ sudo usermod -a -G dialout octoprint
$ cat <<'EOF' | sudo tee /etc/sudoers.d/020_octoprint
octoprint ALL=NOPASSWD: /sbin/shutdown
octoprint ALL=NOPASSWD: /bin/systemctl restart octoprint
EOF
$ echo '' | sudo tee 
$ sudo chmod 440 /etc/sudoers.d/020_octoprint
```

### Systemdの設定

``` shell
$ cat <<'EOF' | sudo tee /etc/systemd/system/octoprint.service
[Unit]
Description=The snappy web interface for your 3D printer
After=network-online.target
Wants=network-online.target

[Service]
Environment="LC_ALL=C.UTF-8"
Environment="LANG=C.UTF-8"
Type=simple
User=octoprint
ExecStart=/usr/local/share/octoprint/venv/bin/octoprint

[Install]
WantedBy=multi-user.target
EOF
$ sudo systemctl daemon-reload
$ sudo systemctl enable octoprint
$ sudo systemctl start octoprint
```

以上でOctoPrintが起動する。
HTTPでRaspbianの5000番ポートへアクセスすることで初回セットアップが始まる。

設定ファイルなどは実行ユーザの`${HOME}/.octoprint`に作成される模様。
今回は`/usr/local/share/.octoprint`になる。

ただし、基本的にはブラウザで設定できるようなのでここのファイルにアクセスすることは少なそう。
ログも`journalctl -u octoprint`で見れる。

## OctoPrintの設定

初回アクセス時の設定ウィザードでひととおり設定できたと思うが振り返っておく。
前回紹介したIUSE IUM1を使う前提の設定なので注意。

|大項目|小項目|値|
|:--|:--|:--|
|Serial Connection|Serial Port|AUTO|
||Baudrate|115200|
|Printer Profiles|Form Factor|Rectangular|
||Origin|Lower Left|
||Heated Bet|No|
||Heated Chamber|No|
||Width|110mm|
||Depth|110mm|
||Height|120mm|
||Nozzle Diameter|0.4mm|
||Number of Extruders|1|
|Server|Restart OctoPrint|sudo systemctl restart octoprint|
||Restart system|sudo shutdown -r now|
||Shutdown system|sudo shutdown -h now|

Printer Profilesで作成したプロファイルをデフォルトプロファイルにしておく。

USBでRaspberry Piとプリンタを接続しConnectボタンを押すことで接続できる。
印刷中の温度の推移やGCodeのプレビュー（ヘッドの軌跡を見れたりできる）を確認したり、手動でヘッドを移動することもできる。
これでPCを繋げなくてもヘッド位置のキャリブレーションができるようになった。

スライスソフトでスライスし、できた`.gcode`をブラウザでアップロードすることで印刷を開始することができる。
SDカードが不要になる。

## Curaプラグイン

SDカードなしで印刷できるのでこれだけでも便利なのだが、スライスソフトのUltimaker CuraにはOctoPrint用のプラグインが存在し、
これを使うことでCuraの画面から直接OctoPrintに`.gcode`をアップロードすることができる。

インストール方法や使い方は以下が参考になる。
[raspberry pi zero wでOctoPrintを動かしてみた - Qiita](https://qiita.com/ysogabe/items/95b974d13b396cf7479e)

以上
