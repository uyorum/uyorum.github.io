+++
slug = ""
tags = ["", ""]
title = "Ubuntu 20.04でMagic Trackpadのマルチタッチジェスチャーを使う"
date = "2020-05-17T21:12:10+09:00"

+++

久しぶりにデスクトップをUbuntuにしてみたところ、Magic Trackpadのジェスチャーの設定に苦戦したのでメモ。

<!-- more -->

## 環境

* Ubuntu 20.04
* X11
* GNOME
* Magic Trackpad (2じゃない)

## 設定

普通にペアリングしてタッチパッドの設定から以下の動作は設定できるようになる。

* スクロール方向
* 左右クリック
* 2本指スクロール

基本的にはこれでも十分使えるのだが、自分の場合は3本指スワイプで戻る・進む動作をさせたかったので方法を調べてみた。
[Ubuntu wiki](https://wiki.ubuntu.com/Multitouch/AppleMagicTrackpad)ではginnというツールが紹介されている。
またいろいろとググっているとtoucheggというツールも見つかる。
どちらも試してみたが自分の環境ではどちらも期待通りに動かなかった。

## ドライバまわりの話

自分の中でLinuxでタッチパッド周りのドライバといえばSynapticsだったが現在はSynapticsは開発されておらず、
代わりにlibinputというドライバが使われるようになっているらしい。

実際にMagic Trackpadにはlibinputが使われている模様。

``` shell
$ xinput list | grep -i trackpad
⎜   ↳ Magic Trackpad                            id=10   [slave  pointer  (2)]
$ xinput list-props 10
Device 'Magic Trackpad':
        Device Enabled (168):   1
        Coordinate Transformation Matrix (170): 1.000000, 0.000000, 0.000000, 0.000000, 1.000000, 0.000000, 0.000000, 0.000000, 1.000000
        libinput Tapping Enabled (303): 1
        libinput Tapping Enabled Default (304): 0
        libinput Tapping Drag Enabled (305):    1
        libinput Tapping Drag Enabled Default (306):    1
        libinput Tapping Drag Lock Enabled (307):       0
        libinput Tapping Drag Lock Enabled Default (308):       0
        libinput Tapping Button Mapping Enabled (309):  1, 0
        libinput Tapping Button Mapping Default (310):  1, 0
        libinput Natural Scrolling Enabled (311):       0
        libinput Natural Scrolling Enabled Default (312):       0
        libinput Scroll Methods Available (313):        1, 1, 0
        libinput Scroll Method Enabled (314):   1, 0, 0
        libinput Scroll Method Enabled Default (315):   1, 0, 0
        libinput Click Methods Available (316): 1, 1
        libinput Click Method Enabled (317):    0, 1
        libinput Click Method Enabled Default (318):    0, 1
        libinput Middle Emulation Enabled (319):        0
        libinput Middle Emulation Enabled Default (320):        0
        libinput Accel Speed (321):     0.551471
        libinput Accel Speed Default (322):     0.000000
        libinput Left Handed Enabled (323):     0
        libinput Left Handed Enabled Default (324):     0
        libinput Send Events Modes Available (288):     1, 0
        libinput Send Events Mode Enabled (289):        0, 0
        libinput Send Events Mode Enabled Default (290):        0, 0
        Device Node (291):      "/dev/input/event5"
        Device Product ID (292):        1452, 782
        libinput Drag Lock Buttons (325):       <no items>
        libinput Horizontal Scroll Enabled (326):       1
```

ginnもtoucheggもsynaptics用に作られているからlibinputの環境では動かないということだろうか？
ともかく、libinputの場合にマルチタッチジェスチャーをするためのツールは[Arch wiki](https://wiki.archlinux.jp/index.php/Libinput#.E3.82.B8.E3.82.A7.E3.82.B9.E3.83.81.E3.83.A3.E3.83.BC)が詳しい。
説明を読んだ感じだとGnomeExtendedGesturesがよさそうだが、Ubuntuにはパッケージがないうえ、[GitHub](https://github.com/mpiannucci/gnome-shell-extended-gestures)を見るとWaylandが必要とのことだったのでlibinput-gesturesを選択した。

## libinput-gestures

libinput-gesturesもパッケージはないので[GitHub](https://github.com/bulletmark/libinput-gestures)からダウンロードしてくる。
インストール方法もREADME.mdに記載の通り。

ひとまず設定ファイルは以下のようにした。

* 3本指左右スワイプで戻る・進む
* 4本指左右スワイプでワークスペース切替
* 3本指または4本指上下スワイプですべてのウィンドウを表示

``` shell
$ cat .config/libinput-gestures.conf
gesture swipe left 3 xdotool key alt+Left
gesture swipe right 3 xdotool key alt+Right

gesture swipe left 4 xdotool key super+Page_Up
gesture swipe right 4 xdotool key super+Page_Down

gesture swipe up 3 xdotool key alt+F1
gesture swipe down 3 xdotool key alt+F1
gesture swipe up 4 xdotool key alt+F1
gesture swipe down 4 xdotool key alt+F1
```

`libinput-gestures -d`でジェスチャーを認識しているか確認できる。
`libinput-gestures-setup start`で起動、`libinput-gestures-setup autostart`で自動起動設定

もっと凝ったジェスチャーも設定できそうだがひとまずこれで使ってみることにする。

## 参考

* [GitHub - bulletmark/libinput-gestures: Actions gestures on your touchpad using libinput](https://github.com/bulletmark/libinput-gestures)
* [libinput - ArchWiki](https://wiki.archlinux.jp/index.php/Libinput)
* [Linux Mint(Cinnamon) で Touchpad gestures を使えるようにした - JUNのブログ](https://jun-networks.hatenablog.com/entry/2018/05/06/071813)
