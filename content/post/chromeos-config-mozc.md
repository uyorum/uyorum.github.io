+++
slug = ""
tags = []
title = "Chrome OSのLinux環境のMozcの設定画面を開く"
date = "2023-04-12T00:55:25+09:00"
+++

Mozcの設定画面を開こうとして苦労したのでメモしておく。

<!--more-->

## 環境

* Crostini (Chrome OS上のLinux環境）
* Fcitxとfcitx-mozcを導入して日本語入力を実現している

## 設定画面の開き方

`fcitx-configtool`や`fcitx-config-gtk3`ではどうやってもFcitxの設定にしか行けず、Mozcの設定画面へアクセスできませんでした。
Webで検索しても見つからず、Mozc関連のコマンドでもあるのかとディスクを漁ったところ手がかりになりそうなファイルを発見。

``` shell
$ find / -type f -name '*mozc*'
...
/usr/share/applications/setup-mozc.desktop
...
```

中身はこんな感じ

``` ini
[Desktop Entry]
Name=Mozc Setup
Name[ja]=Mozc の設定
Comment=Set up Mozc engine
Comment[ja]=Mozc エンジンを設定します
Exec=/usr/lib/mozc/mozc_tool --mode=config_dialog
Icon=/usr/share/icons/mozc/product_icon_32bpp-128.png
Type=Application
StartupNotify=true
Categories=Settings;
X-Desktop-File-Install-Version=0.26
```

Exec行のコマンドがそれっぽいです。というわけでコマンドを特定することができました。

``` shell
$ /usr/lib/mozc/mozc_tool --mode=config_dialog
```

![mozc_config.jpg](/chromeos-config-mozc/mozc_config.jpg)

このときは常に半角スペースを入力するように設定したかったのでした。