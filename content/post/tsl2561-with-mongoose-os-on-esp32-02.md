+++
date = "2017-09-02T10:41:35+09:00"
slug = ""
tags = ["",""]
title = "ESP32とMongooseOSを使ってTSL2561で照度を取得する(実装編)"
aliases = ["/blog/tsl2561-with-mongoose-os-on-esp32-02/"]

+++

[前回](../tsl2561-with-mongoose-os-on-esp32-01/)の続き．
Mongoose OSの設定とTSL2561を使うためのコードを書いていく．

<!--more-->

## 設計
今回は1分ごとにTSL2561で照度を取得し，MQTTで値をPublishすることにする．
細かいパラメータ等は以下のようにする．

### TSL2561
前回参考にした記事[^1]でも説明されている通り，TSL2561にはGainとIntegration Timeという設定項目がある．
本来は，使用する環境下で想定される照度に合わせて適切な値を選択するか現在の照度に応じて自動で調整すべきものである．
今回はひとまず，それぞれデフォルト値で使用する．

* Gain: 1x
* Integration Time: 402ms
* Scale: (16 / `Gain`) * (402 / `Integration Time`) = 16

### MQTT
今回は自分で立てたBrokerを使う．Topicは任意だがこの記事内では以下のようにする．

* ホスト名: broker.example.com:1883
* 認証: なし
* Topic: home/brightness
* QoS: 0

## センサーの接続
I2Cデバイスのピンをどのピンに接続すればよいのかわからずにここで結構時間を使った．
`mos`で起動するMongoose OSのWeb UIから`Device Config`→`Expert View`からI2Cようの設定を見ることができる．自分の環境ではデフォルトで以下のようになっていた．
sda端子を32ピン，scl端子を33ピンに接続すればよいことがわかる．

``` json
"i2c": {
  "enable": true,
  "freq": 100000,
  "debug": false,
  "sda_gpio": 32,
  "scl_gpio": 33
},
```

その他にVinを3.3V端子，GNDを適当なGNDピンに接続した．

## MQTTの設定
Brokerと認証の設定を行う．
`Device Config`→`Simple View`→`MQTT Settings`で設定を行うのがおそらく最も簡単．

![01.jpg](/tsl2561-with-mongoose-os-on-esp32-02/01.jpg)

## コード
`Device Files`→`init.js`へ移動し，コードを書いていく．
基本的には[前回](../tsl2561-with-mongoose-os-on-esp32-01/)実装したアルゴリズムを移植するだけ．I2Cデバイス操作用の関数はいくつかMongoose OSで用意されている．詳細はドキュメント[^2]を参照．

<script src="https://gist.github.com/uyorum/f988ab4bd4ae90fb5dd7c6950e6c7110.js"></script>

コードを書いたら画面上の`Save + Reboot`でESP32上にコードをデプロイする．1分ごとに照度を取得しBrokerにPublishするようになる．

## やりたいこと
* 今回書いたコードをライブラリにしてMongoose OSで簡単に利用できるようにしたい

以上

[^1]: [Raspberry pi 3でストロベリー・リナックス社製「TSL2561 照度センサ・モジュール メーカー品番：TSL2561」を使う（試行錯誤編） - Qiita](http://qiita.com/boyaki_machine/items/a238e9d03455a2eea26e)
[^2]: [Mongoose OS Documentation](https://mongoose-os.com/docs/libraries/hardware/i2c.html)
