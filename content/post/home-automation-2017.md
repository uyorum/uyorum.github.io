+++
date = "2017-12-30T00:15:15+09:00"
slug = ""
tags = ["ホームオートメーション", "Home Assistant"]
title = "ホームオートメーションの現状まとめ@2017"
aliases = ["/blog/home-automation-2017/"]

+++

今年はホームオートメーションにたくさん取り組んだ年だった．
年末ということでキリもよいので現状の我が家がどうなっているかまとめておく．

<!--more-->

## アーキテクチャ

![01.png](/home-automation-2017/01.png)

基本的にHome Assistant[^1]というソフトウェアを中心に構成している．  
Home Assistantについては以前にも記事を書いた．  
[Home Assistantでつくるホームオートメーション(導入編) - @uyorumの雑記帳](/blog/home-assistant-install/)

自分の環境ではRaspberry Pi 3BにRaspbianをインストールして使っている．  
上ではHome Assistant，Mosquitto(MQTT Broker)[^2]やいくつかの自作プログラムが動いている．これらのサービスはすべてDocker上で動かしている．  
ちなみにARM用のHome Assistantの公式イメージはないため，[これ](https://github.com/lroguet/rpi-home-assistant)を使っている．

### Limitless LED

照明にはLimitless LED(MiLight)というLED電球を使用している．この手の分野はPhilips Hueが定番だが価格の安さで採用した．  
狭い賃貸だがすべてのエリアの照明をこれで置き換えている．

### ESP32

秋月で買ったESP32-DevKitC[^3]にMongoose OSというOS[^4]をインストールして使っている．  
Mongoose OSを使う必然性はないが，単純に使ってみたかったので採用した．

玄関付近とトイレのドアに設置し，GPIOでIRセンサーと開閉スイッチを制御している．反応があったらMosquittoへPublishするようにしている．  
Mongoose OSはJavaScriptでコードを書けるのとライブラリが充実しているので実装はかなり楽だった．  
Home AssistantはMosquittoをSubscribeしており，値を見てLimitless LEDの点灯・消灯を制御している．  
[Home Assistantで人感センサーを使って照明を自動点灯する - @uyorumの雑記帳](/blog/home-assistant-gpio/)

### Sonoff

Sonoffとは，ITEAD Studio社が販売しているWi-Fiスイッチ．100Vケーブルの途中にこれを挟むことでネットワーク越しに電源のON/OFFを制御できる．  
中身はESP8266であり，コンソールをひっぱり出して独自のソフトウェアを焼くハックがいくつか存在する．

自分はこれをHome Assistantから操作したかったので[こちら](https://github.com/arendst/Sonoff-Tasmota)を焼いて使っている．  
これによりWebAPIとMQTTから操作できるようになる．

### IRKit[^5]

主にエアコン，ディスプレイ，AVアンプのON/OFFのために設置している．
IRKitのAPIは赤外線情報をPOSTするという仕様だが，それだと少々使いづらいため，コマンドを指定するとあらかじめ定義した赤外線情報をIRKitのAPIへPOSTしてくれるプロキシサーバを作った．[uyorum/irkit-ha: Home-Assistant-compatible irkit server](https://github.com/uyorum/irkit-ha)  
これをHome Assistantの[REST Component](https://home-assistant.io/components/notify.rest/)からつっついている．

ちなみに実装した後から気づいたのだがHome Assistantには[Remote Component](https://home-assistant.io/components/remote/)があるので，これにならってIRKit用のComponentを実装すればこのようなサーバは必要なかった．

### Amazon Dash Button

正規の使い方はしておらず，Home Assistantと連携させて電球やディスプレイのON/OFFに使用している．
[Home AssistantとAmazon Dash Buttonを連携させる - @uyorumの雑記帳](/blog/home-assistant-with-dash-button/)

ただし最近はGoogle HomeとHome Assistantを連携させたので，Dash Buttonはほとんど使っていない．

### 在宅管理

Home Assistantの[Bluetooth Tracker](https://home-assistant.io/components/device_tracker.bluetooth_tracker/)というComponentを使って自分のスマートフォンを検知するようにしている．  
自分が帰宅したら電気をつけ，外出したら電気を消すようにしている．

### Google Home

Home Assistantの[Google Assistant Component](https://home-assistant.io/components/google_assistant/)を使って，Google Assistantから電球，エアコン，ディスプレイを操作できるようにしている．
(エアコンとディスプレイは前述のIRKit経由で)

## 問題点

### ネットワークがSPoF

現状，ネットワークSPoFになってしまっている．そのためルーターがダウンした場合，下手をすると電気をつけることすらできなくなってしまう．  
さすがにこれでは不便なので，物理的なインターフェースを適宜残しておく必要がありそう．

### Home Assistant経由で操作しないと状態の不一致が起こる

Home Assistantは例えば電球などの電源状態を管理しており，Home Assistantを介さずに操作してしまうと状態の不一致が起こってしまい予期せぬ動作の原因となる．  
そのため，基本的にはHome Assistantを介して操作することになり，それが理由で使用できるデバイスに制約が発生したりする．

例えば，自分はIRKitのグレードアップ版のNatureRemoも持っているのだが，NatureRemoはまだAPIが実装されていないためHome Assistantから操作することができず[^6]，NatureRemoは今のところほとんど使えていない．

## 最後に

非常にざっくりとだが現状をまとめた．ちなみにここで紹介した以外にも，導入したが活用できていないセンサー類やデバイスが数多くある．  
気の利いたことをしようとすると，いろいろと試行錯誤や開発が必要になるが，例えば照明はHueとIFTTT，Google Home(またはAlexa)を使えば非常に簡単に自動化，音声操作できるようになる．  
現在の我が家は，寝るとき以外はほぼ全て自動で適切なタイミングで電気が点灯・消灯するようになっている．(寝るときは「OK Google, 電気を消して」とGoogle Homeに話しかける)
これだけでもかなり便利になるのでぜひやってみてほしい．

[^1]: [Home Assistant](https://home-assistant.io/)
[^2]: [An Open Source MQTT v3.1 Broker](https://mosquitto.org/)
[^3]: [ＥＳＰ３２－ＤｅｖＫｉｔＣ ＥＳＰ－ＷＲＯＯＭ－３２開発ボード: 無線、高周波関連商品 秋月電子通商 電子部品 ネット通販](http://akizukidenshi.com/catalog/g/gM-11819/)
[^4]: [Mongoose OS - reduce IoT firmware development time up to 90%](https://mongoose-os.com/)
[^5]: [IRKit - Open Source WiFi Connected Infrared Remote Controller](http://getirkit.com/)
[^6]: IFTTTを経由するようにすればHome Assistantからも操作できるが，コマンドの数だけAppletを作ることになり現実的ではない
