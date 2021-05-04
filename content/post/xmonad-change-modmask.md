+++
Categories = []
Tags = []
title = "Xmonadのmodキーを半角/全角キーに変更する"
date = "2015-02-22T19:04:51+09:00"
aliases = ["/blog/xmonad-change-modmask/"]

+++

Xmonadを使い始めました．
いろいろ設定方法を紹介しているページは見つかるのですがmodキーをAltまたはWindowsキー以外に設定する方法が見つからなかったのでメモ．

<!--more-->

## 経緯
いろいろググってみてもmodキーをWindowsキーに変更しているページしか見つかりませんでした．
Windowsキーのあるキーボードの右下はなかなか指が届きづらいため別のキーにしたいと考えました．
自分はSKKを使っているので全角/半角キーは使いません．この位置ならば割と容易に届くためmodキーにこのキーを使うことにしました．

## 設定方法

* xmonad.hs

よく紹介されているようにmodMaskをmod4Maskに割り当てます

    modMask = mod4Mask

* Xmodmap

mod4に全角/半角キーを追加します

    keysym Zenkaku_Hankaku = Super_L
    add mod4 = Zenkaku_Hankaku

あとは設定を読み込ませてやればOKです．
なんでmod4MaskでWindowsキーになるのか不思議だったのですがXmodmapで割り当てられていたんですね．
