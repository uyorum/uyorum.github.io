+++
date = "2018-06-28T15:06:06+09:00"
slug = ""
tags = ["",""]
title = "Home AssistantのデプロイをHass.ioにした"
aliases = ["/blog/hassio-introduction/"]

+++

これまでHome AssistantはRaspbianにインストールしたDocker上で動かしていたがHass.ioに移行した．  
移行にあたって実施したことをまとめておく．

<!--more-->

## Hass.ioとは
[Hass.io - Home Assistant](https://www.home-assistant.io/hassio/)

Home Assistantインストール済みのOSイメージ．Home Assistantに加えて様々な追加機能が実装されており，Home AssistantのUIから制御することができる．

## なぜ移行したか
これまでのデプロイ方法では以下の点で課題を感じていた．

### Home Assistantのバージョンアップ方法  
これまで使用していたコンテナイメージは，Home Assisstantのリリースごとにタグがわけられていたため，別のバージョンのHome Assistantをデプロイするには以下のようなことをする必要があった．

```
1. 新しいタグのイメージをpull
2. 現在動いている古いタグのコンテナを停止
3. 新しいタグのイメージを使ってrun
```

そのためこれまでは新しいバージョンがリリースされるとRaspbianにSSHでログインし，上のコマンドを実行するシェルスクリプトを叩いていた．  
自動化しようにも手順2でHome Assistantを停止するため，一連の操作はHome Assistant自身では完結させることはできず，これをキックする別のデーモンが必要になる．

### 別のサービスをHome Assistantから制御できない
Home Assistantと合わせていくつかのソフトウェアをHome Assistantと同様にDocker上にデプロイしていた．

これらはHome Assistantと同じDockerホスト上にデプロイしており，例えば新しいイメージに更新したい場合は上と同様にRaspbianにSSHでログインして`docker`コマンドを叩いていた．  
Home Assistantから制御するにはHome AssistantにDockerのAPIを叩かせることになり，これは避けたかった．

####  [uyorum/rpi-python-firetv](https://github.com/uyorum/rpi-python-firetv)
[こちら](https://github.com/happyleavesaoc/python-firetv)上で開発されているソフトウェア．Amazon FireTVを操作するREST APIを提供する．  
Home AssistantからこのAPIを叩いてFireTVを制御する．

#### [uyorum/dash-ha](https://github.com/uyorum/dash-ha)
mazon Dash ButtonをトリガーにHome Assistantのイベントを発火させる．[詳細は過去に記事を書いた](/blog/home-assistant-with-dash-button/)

### バックアップ方法
Home Assistantには自身をバックアップする手段は提供されておらず，定期的なバックアップをするには若干の作り込みが発生する．  
やればいいだけなのだが面倒で後回しにしていた．

## 移行にあたって行ったこと
### MicroSDカードを追加で買う
厳密には必要ないが，他でMicroSDを使うあてがあったのと，念のためいつでも切り戻しができるようにしておきたかったためMicroSDカードを追加で購入した．

### ドキュメントに従ってインストール
[公式ドキュメント](https://www.home-assistant.io/hassio/installation/)に従ってインストール．  
とはいえイメージをSDカードに焼くだけ．

### 過去のデータは破棄する
作業を簡単にするため，過去の収集データはHass.ioに移行はせず，すべて破棄することにした．  
移行するならHome Assistantのconfigurationディレクトリにある`home-assistant_v2.db`を持っていくことになるはず(未確認)

### コンフィグを投入
[Web UIから設定できるadd-onがある](https://www.home-assistant.io/addons/configurator/)のだが，自分の環境ではうまく動かなかったのでひとまずは[SSH Server add-on](https://www.home-assistant.io/addons/ssh/)でSSHログインして`vim`で設定を書いていった．  
設定ファイル群にはログイン後の`/config`あたりからアクセスできる．

### いくつかのAdd-onを有効化
SSH Add-onに加えていくつかのAdd-onも有効化していく．

#### Bluetooth BCM43xx
Raspbery Pi3のBluetoothを使うために必要．Bluetooth Tracker Componentで使う

#### Mosquitto broker
MQTTはいくつかのデバイスで使っているため入れる．Home Assistantの設定は以下のような感じにした．ホスト名を`core-mosquitto`と指定するのがポイント

``` yaml
mqtt:
  broker: core-mosquitto
  port: 1883
  client_id: hass
  keepalive: 60
  birth_message:
    topic: "home/hass/state"
    payload: "Online"
    qos: 1
    retain: true
  will_message:
    topic: "home/hass/state"
    payload: "Offline"
    qos: 1
    retain: true
```

### 自作サービスのAdd-on化
続いて上述の2つのサービスをHass.ioのAdd-onとして実装していく．
Add-onの作り方は[開発者用のドキュメント](https://developers.home-assistant.io/docs/en/hassio_addon_index.html)があるので，これを参照する．
どうやら中身はDockerコンテナのよう．Dockerでできることはだいたいできそうだった．ただしAdd-on同士の通信やAdd-onとHome Assistantの通信はホスト名の指定に若干のクセがあった．

できたAdd-onは[こちら](https://github.com/uyorum/hassio-addons)

## 抱えていた課題はどうなったか
### Home Assistantのバージョンアップ方法
* Web UIからワンクリックで実行できるようになった
* おそらくAPIかコマンドでも実行できるはず(未確認)
    * それができれば例えば新しいバージョンがリリースされたら外出中に自動でアップグレードといったことが自動でできる

### 別のサービスをHome Assistantから制御できない
* すべてHass.ioのAdd-onとして実装できたため，起動/停止/アップグレードなどはHass.ioから制御できるようになった

### バックアップ方法
* ローカルへのバックアップWeb UIからワンクリックで実行できるようになった
    * Add-onの設定などもバックアップできるので楽になった
* Add-onとしてよりリッチなバックアップ(例えばクラウド上にアップロードするなど)も実装できそう

## まとめ
OSやPython実行環境のレイヤーがほとんど隠蔽されているため，Hass.ioを使うことでよりHome Assistantを使うことに集中できるようになった．  
また，使い始める前はオールインワンが故に汎用性や自由度の低さを懸念していたが，Add-on機構の完成度が高く，自由度もある．さらにHome Assistantと独立したサービスとしてデプロイするよりは管理がしやすくなった．

以上
