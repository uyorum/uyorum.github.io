+++
date = "2017-06-10T20:20:04+09:00"
slug = ""
tags = ["",""]
title = "Home AssistantとAmazon Dash Buttonを連携させる"

+++

Amazon Dash Buttonは間違った使い方ができることで有名だが，Amazon Dash ButtonからHome Assistantでアクションをキックできるようにしてみる．

<!--more-->

## Amazon Dash Buttonのハック
ネットに情報は溢れているため詳しい説明は省略する．  
本来のAmazon Dash Buttonはボタンを押すことであらかじめ設定した商品を注文するためのものだが，その過程で発生するパケットをトリガーに利用して，
ボタンを押すことで任意の処理を実行させようというもの．

## 仕組みの概要
Amazon Dash Buttonと連携するComponentは過去に提案されている．  
[Amazon Dash Component? · Issue #484 · home-assistant/home-assistant](https://github.com/home-assistant/home-assistant/issues/484)

主に以下の理由により却下されている

* Dash ButtonのためだけにHome Assistantをrootで動かすのは受け入れられない
* Dash Buttonの代わりにAWS IoTボタンやESP8266を使えば同じようなことが実現できる

このIssueの中では[maddox/dasher](https://github.com/maddox/dasher)を使うよう提案されているが，いくつかの個人的な理由によりツールを自作した．

* 検知対象に利用している`ARP probe`パケットが自分の環境ではほとんどキャプチャできなかった
* Home Assistant用として使うには設定ファイルが複雑すぎる
* Node.jsがよくわからない

作成したコードは[Github](https://github.com/uyorum/play-amazon-dash-button/tree/master/home-assistant)で公開している．

* `ARP probe`の代わりに`DHCP Discover`パケットをキャプチャする
* 設定ファイルに書く内容は，Home Assistantと組み合わせて使用するための最低限の項目に絞っている
* Python製

仕組みは以下の通り

1. `dash-ha`サーバでボタン押下を検知
1. ボタンのMACアドレスに応じて，Home AssistantへREST APIでイベントを発火させる
1. Home AssistantのAutomationでそのイベントをトリガーにアクションが実行されるようにしておく
1. ボタンを押すとそのAutomationが実行される

## ボタン押下を検知するサーバの用意
ボタン検知を検知するためのサーバを用意し，専用のプログラムを走らせておく．自分はHome Assistantが稼動しているRaspbery Pi 2 Model Bで動かしている．
以下のような感じでインストールする．

``` shell
$ sudo apt -y install tcpdump python-scapy
$ sudo mkdir /srv/dash-ha
$ cd /srv/dash-ha
$ sudo wget https://raw.githubusercontent.com/uyorum/play-amazon-dash-button/master/home-assistant/dash-ha.py
$ sudo chmod +x dash-ha.py
```

設定ファイルは以下のような内容

``` shell
$ cat /srv/dash-ha/config.yaml
home_assistant:
  host: 127.0.0.1
  port: 8123
buttons:
  - mac: XX:XX:XX:XX:XX:XX
    event: dash_button_nescafe
  - mac: YY:YY:YY:YY:YY:YY
    event: dash_button_evian
```

上の例だと，MACアドレス`XX:XX:XX:XX:XX:XX`のDash Buttonが押されるとHome Assistantで`dash_button_nescafe`というイベントが発火するようになる．  
いちおうHome Assistant側で認証を有効にしていた場合も対応できるようしている．(Githubに上げた設定例を参照)

起動，停止はSystemdで管理する．


``` shell
$ systemctl cat dash-ha
# /etc/systemd/system/dash-ha.service
[Unit]
Description=Integrate Amazon Dash Button and Home Assistant
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python /srv/dash-ha/dash-ha.py
Restart=always

[Install]
WantedBy=multi-user.target
$ sudo systemctl enable dash-ha
$ sudo systemctl start dash-ha
```

## Home Assitatntの設定
Home Assistant側ではイベント`dash_button_nescafe`をトリガーとするAutomationを設定しておく．

``` yaml
automation:
  - alias: Toggle ceiling light
    trigger:
      platform: event
      event_type: dash_button_nescafe
    action:
      service: homeassistant.toggle
      entity_id: light.livingroom_ceiling_light
```

これでボタン押下を検知したらアクションが実行されるようになる．

以上．
