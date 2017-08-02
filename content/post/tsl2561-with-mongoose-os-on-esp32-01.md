+++
date = "2017-08-02T20:53:04+09:00"
slug = ""
tags = ["",""]
title = "ESP32とMongooseOSを使ってTSL2561で照度を取得する(準備編)"

+++

かねてから触ってみたいと思っていたMongooseOSと以前買ったTSL2561照度センサーモジュールがあったのでESP32にMongooseOSを入れて照度を取得してみようと思った．  
そもそもI2Cデバイスを触るのが初めてだったため、いきなりMongooseOSでそれを扱おうとするのはハードルが高すぎると考え、まずはその準備編として情報の多いRaspberryPiで照度を取得してみることにした．  
最後にESP32へのMongooseOSのインストールも行っておく．

<!--more-->

## 環境
### 作業端末

``` shell
$ sw_vers
ProductName:    Mac OS X
ProductVersion: 10.11.6
BuildVersion:   15G1611
```

### ハードウェア
* [ＴＳＬ２５６１使用　照度センサーモジュール: センサ一般 秋月電子通商 電子部品 ネット通販](http://akizukidenshi.com/catalog/g/gM-08219/)
* [ＥＳＰ３２－ＤｅｖＫｉｔＣ　ＥＳＰ－ＷＲＯＯＭ－３２開発ボード: 無線、高周波関連商品 秋月電子通商 電子部品 ネット通販](http://akizukidenshi.com/catalog/g/gM-11819/)

## RaspberryPiでTSL2561を扱う
### Rasbianのセットアップ
I2C向けのセットアップは以下の書籍を参考にした．  
[Raspberry Piで学ぶ電子工作　超小型コンピュータで電子回路を制御する　サポートページ｜ブルーバックス｜講談社BOOK倶楽部](http://bluebacks.kodansha.co.jp/special/rspi.html)

``` shell
$ sudo raspi-config
(Interfacing -> I2C -> enable)
$ sudo reboot
$ sudo apt-get update
$ sudo apt-get install -y i2c-tools python-smbus
```

センサーモジュールの各端子はRaspberryPiの以下のピンに接続する

|センサーモジュール|RasPi|
|:--|:--|
|Vin|3.3V (1ピン)|
|GND|GND (6ピン)|
|SDA|I2C SDA (3ピン)|
|SDL|I2C SCL (5ピン)|

### コードの実装
続いて以下のエントリとデータシートを参照し、Pythonで照度を取得するコードを書いてみた  
[Raspberry pi 3でストロベリー・リナックス社製「TSL2561 照度センサ・モジュール メーカー品番：TSL2561」を使う（試行錯誤編） - Qiita](http://qiita.com/boyaki_machine/items/a238e9d03455a2eea26e)  
段階を踏んでセンサーデータの取得からルクスの計算まで説明されており非常に参考になった

書いたコードは→ [tsl2561.py](https://gist.github.com/uyorum/966af625bd9893ea3b2877e4e40600df)

## Mongoose OSのインストール
* [Mongoose OS - Downloads](https://mongoose-os.com/software.html) の内容に従ってコマンドラインツール`mos`をインストールしておく
* [USB - UART ブリッジ VCP ドライバ|Silicon Labs](https://jp.silabs.com/products/development-tools/software/usb-to-uart-bridge-vcp-drivers) からドライバをダウンロード、インストールしておく

ESP32へのMongooseOSのインストールは公式サイト記載の方法ではうまくいかなった．いろいろ調べたところ以下の方法でインストールできた．

``` shell
$ mos flash --firmware https://mongoose-os.com/downloads/mos-esp32.zip
$ mos wifi <SSID> <PASSWORD>
```

コマンド`mos`を実行するとブラウザが起動してGUIからMongooseOSを操作できるようになる．コードもここで書いていくことになる．

ここまででTSL2561の扱いの理解とMongooseOSでコードを書く準備ができた．続いてMongooseOS用のコードを実装していく．

続く

## 参考資料
* [Raspberry Piで学ぶ電子工作　超小型コンピュータで電子回路を制御する　サポートページ｜ブルーバックス｜講談社BOOK倶楽部](http://bluebacks.kodansha.co.jp/special/rspi.html)
* [Raspberry pi 3でストロベリー・リナックス社製「TSL2561 照度センサ・モジュール メーカー品番：TSL2561」を使う（試行錯誤編） - Qiita](http://qiita.com/boyaki_machine/items/a238e9d03455a2eea26e)
