+++
title = "Home Assistantでつくるホームオートメーション(導入編)"
tags = ["",""]
slug = ""
date = "2017-04-22T21:48:00+09:00"

+++

ホームオートメーション/スマートホーム化を実現できるOSSのHome Asssitantについて

<!-- more -->

## Home Assitantとは
* [Home Assistant](https://home-assistant.io/)
* [home-assistant/home-assistant: Open-source home automation platform running on Python 3](https://github.com/home-assistant/home-assistant)

ホームオートメーションを実現するためのソフトウェア．Githubで開発されており，Python3で書かれている．
様々なサービス，センサー，家電に対応しておりブラウザでそれらの状態を確認，操作するためのUIが提供されている．
また，特定のトリガーとアクションをあらかじめ定義しておくことでそれらを自動制御することもできる．

同様のソフトウェアとして，以下のようなソフトウェアもある

* [openHAB](https://www.openhab.org/)
* [Domoticz](https://domoticz.com/)
* [HomeBridge](https://www.homebridge.com/)

2017/4/22時点でGithubのスター数は以下のような感じでHome Assistantが一番人気がありそう．

* Home Assistant…6583
* openHAB…241
* Domoticz…651
* HomeBridge…4903

公式サイトでデモ画面を見ることができる．[Home Assistant Demo](https://home-assistant.io/demo/)

## インストール
[Installation of Home Assistant - Home Assistant](https://home-assistant.io/docs/installation/)

様々のインストール方法が提供されている．自分はRaspberryPiでGPIOを使いたかったためRaspbianへのManual Installを選択した．

systemdのユニットファイルも提供されている．自分は多少変更して以下のようにした．

* /etc/systemd/system/home-assistant.service

```
[Unit]
Description=Home Assistant
After=network.target

[Service]
Type=simple
User=ha
ExecStart=/srv/homeassistant/bin/hass -c "/home/ha/.homeassistant"

[Install]
WantedBy=multi-user.target
```

「ha」という名前でシステムユーザを作成し，このユーザでHome Assistantを実行するようにしている．

参考: [Autostart using systemd - Home Assistant](https://home-assistant.io/docs/autostart/systemd/)

* 有効化

``` shell
$ sudo systemctl daemon-reload
$ sudo systemctl enable home-assistant
$ sudo systemctl start home-assistant
```

初回起動時はコンポーネントのインストールがあるため10分ほどかかる．
ブラウザでポート8123へアクセスするとWebUIが表示される．

実行ユーザのホームディレクトリに`.homeassistant/configuration.yaml`というファイルが自動で作成される．基本的に設定はこのファイルにYAML形式で書いていくことになる．

## 概念
Home Asssistantで扱うリソースはComponentという形で提供されており[ここ](https://home-assistant.io/components/)から確認できる．これを書いている時点でComponentは640個ある．
個々のComponentはPlatform(Serviceと表記されることもある)としてグルーピングされており，設定方法や可能な操作はPlatformごとに決まっている．
Platformには例えば以下のようなものがある．

* [Media Player](https://home-assistant.io/components/media_player/)  
    Google Cast，Amazon Fire TV，Apple TV，Kodiなど，再生/停止/音量などのインターフェースを持つもの
* [Lights](https://home-assistant.io/components/light/)  
    Philips Hue，MiLight(LimitlessLED)など，点灯/消灯/照度/色温度などのインターフェースを持つもの
* [Switches](https://home-assistant.io/components/switch/)  
    Belkin WeMo，D-Link Smart Plugなど，ON/OFFのインターフェースを持つもの
* [Notifications](https://home-assistant.io/components/notify/)  
    Slack，Pushbulletなど，メッセージを与えるもの
* Sensor  
    Netatmo，Zabbix，OpenWeatherMapなど，数値や文字列を取得できるもの
* [Binary Sensor](https://home-assistant.io/components/binary_sensor/)  
    0/1の値を取得できるもの

ひとつのWebサービスやデバイスでもインターフェースによっては複数のPlatformにComponentが用意されていることがある．  
また，それぞれのPlatformには，Webサービスやデバイスの他にREST，Commandといった汎用的なComponentも用意されているため結構いろいろできる．

ひとまずこれくらいを知っておくとスムーズに使い始めることができるはず．

以上
