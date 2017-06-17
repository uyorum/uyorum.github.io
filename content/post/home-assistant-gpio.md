+++
date = "2017-04-23T21:33:54+09:00"
title = "Home Assistantで人感センサーを使って照明を自動点灯する"
tags = ["",""]
slug = ""

+++

Home Assistantで人感センサーを使って自宅の廊下の電球を点灯/消灯するシステムを組んでみる．

<!--more-->

## 使用製品
今回使用するセンサー，機器は以下の通り

* Raspbery Pi 2 Model B  
Raspbian jessie liteの上にHome Assistantをインストール済み

* 赤外線人感センサー SB612A  
[秋月電子](http://akizukidenshi.com/catalog/g/gM-08767/)で購入．Raspberry Piから電源を取るので3.3Vまたは5Vで動くものなら何でもいいと思う．

* WiFi LED電球 MiLight
[楽天のイルミカ](http://item.rakuten.co.jp/illumica/c/0000000205/)で[ブリッジ](http://item.rakuten.co.jp/illumica/it_m005/)と[電球](http://item.rakuten.co.jp/illumica/it_m003/)を購入．  
スマホアプリを使って操作できるところまでセットアップしておく．資金に余裕があるならHueでもいいと思う．

## 概要
やりたいことは以下の通り

1. 人感センサーを使って人が近づいたことを検知できるようにしておく
1. センサーに反応があった場合，MiLightへリクエストを発行し電球を点灯
1. センサーに反応がなくなってしばらく経ってからMiLightへリクエストを発行し電球を消灯

## Home AssistantでGPIOを使う
秋月のサイトにあるSB612Aのデータシートを見ると以下のことがわかる．

* VCC端子に電源を接続する(DC3.3〜12V)
* センサーの反応はTEST端子から取れる．TEST端子の電位がそれぞれ反応あり=3.3V，反応なし=0Vになる．ただし実際には，センサーに反応がなくなってから0Vになるまではタイムラグがある
* 上記タイムラグ(Delay Time)は2秒〜80分で調整できる

今回の設計は以下のようにする

* VCC端子を3.3V端子(ピン1)へ接続
* TEST端子をGPIO 4端子へ接続
* GND端子をGND(ピン6)へ接続
* Delay timeは最短の2秒とする
* TEST=0Vの状態を確実にGPIOのLOW状態とするためにRaspberryPiに内蔵のプルダウン抵抗を有効にする
* bouncetimeは50msとする

![01.jpg](/home-assistant-gpio/01.jpg)

Home Assistantの設定は以下のようになる．

* configration.yaml

```yaml
binary_sensor:
  - platform: rpi_gpio
    ports:
      4: PIR Sensor
    pull_mode: down
    bouncetime: 50
    invert_logic: false
```

なおGPIO端子の操作にはOS上で相応の権限が必要となる．今回使用しているRaspbian Jessieの場合はHome Assistantの実行ユーザを`gpio`グループに所属させればよい．

``` shell
$ sudo usermod -a -G gpio ha
$ sudo systemctl restart home-assistant
```

## Home AssistantでMiLightを使う
MiLight(中身はLimitlessLED)ははじめからComponentとして提供されているためこれを利用する．[LimitlessLED - Home Assistant](https://home-assistant.io/components/light.limitlessled/)

* configuration.yaml

``` yaml
light:
  - platform: limitlessled
    bridges:
      - host: x.x.x.x
        version: 5
        port: 8899
        groups:
          - number: 1
            name: MiLight
            type: rgbw
```

* イルミカで購入できるWiFiブリッジはVersion 5，カラー電球のタイプはrgbw(rgbwwではない)
* グループ番号はタイプごとに1~4のいずれかになる．今回はrgbwグループのグループ1に登録している

なお，Home AssistantはWebインターフェースで設定ファイルを読み直すことができるが，プロセスの再起動を行わないと反映されないものが多い．
確実に設定を反映させるため，プロセスの再起動を行う．

``` shell
$ sudo systemctl restart home-assistant
```

## Automationを設定する

ここまでで，WebインターフェースではセンサーのON/OFFが表示され，MiLightを操作できるようになっているはず．
次に，これらを組み合わせて以下の動作を実現する．

* センサーに反応があった場合にMiLightを点灯する
* 明るさは255段階(Home Assistant上での値)中，150とする  
    ただしMiLightとしては，v4のWiFiブリッジでRGBWを使用する場合は25段階にしか調節できないそうなので，実際には25段階中15くらい
* センサーに反応がない状態が1分後続くと消灯する

設定は以下のようになる

* configuration.yaml

``` yaml
- alias: Turn on light
  trigger:
    platform: state
    entity_id: binary_sensor.pir_sensor
    state: 'on'
  action:
    service: homeassistant.turn_on
    entity_id: light.milight
    data:
      brightness: 150
- alias: Turn off light
  trigger:
    platform: state
    entity_id: binary_sensor.pir_sensor
    state: 'off'
    for:
      minutes: 1
  action:
    service: homeassistant.turn_off
    entity_id: light.milight
```

ハマった箇所をいくつか

### entity\_idの命名規則
entity\_idに指定する名前はそれぞれのComponentで設定した`name`値になる．空白や大文字はスネークケースへ変換される．
つまり，nameを「PIR Sensor」のようにした場合，entity\_idでは「pir_sensor」のように指定する

### 「ある状態が一定時間続く」をトリガーにする
action内では一定時間の経過を待つ`delay`文が使える

``` yaml
- alias: Turn off light
  trigger:
    platform: state
    entity_id: binary_sensor.pir_sensor
    state: 'off'
  action:
    - delay: 0:01
    - service: homeassistant.turn_off
      entity_id: light.milight
```

だが，これでは「センサーに反応がなくなってから1分後」になるため，例えば30秒後にセンサーに反応が戻っても結局そのまま消灯してしまう．  
しばらく悩んでいたのだが，Triggerで`for`を使うことで希望の動作ができることがわかったので簡単に希望の動作を実現できた．

## 参考
* [プログラマブル電球milightで遊ぼう(RGBW/DW) - takashiskiのブログ](http://takashiski.hatenablog.com/entry/2016/01/12/000658)
* [Raspberry PI GPIO Binary Sensor - Home Assistant](https://home-assistant.io/components/binary_sensor.rpi_gpio/)
* [LimitlessLED - Home Assistant](https://home-assistant.io/components/light.limitlessled/)
* [Automating Home Assistant - Home Assistant](https://home-assistant.io/docs/automation/)
* [Turn on lights for 10 minutes after motion detected - Home Assistant](https://home-assistant.io/cookbook/turn_on_light_for_10_minutes_when_motion_detected/)
