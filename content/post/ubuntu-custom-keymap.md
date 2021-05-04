+++
slug = ""
tags = ["", ""]
title = "Ubuntu 20.04でキーマップをカスタマイズする"
date = "2020-05-20T23:43:30+09:00"
aliases = ["/blog/ubuntu-custom-keymap/"]

+++

前回に引き続き、久しぶりにUbuntuを触ったらてこずったのでメモ。

<!-- more -->

Linuxでキーマップをカスタマイズする方法といったらXmodmapだったが[現在は違うらしい](https://help.ubuntu.com/community/Custom%20keyboard%20layout%20definitions)。
Xmodmapでも一時的にキーマップは変わるが、いつのまにか元に戻ってしまう。
代わりに現在ではxkbというものを使うらしい。

調べたところ設定方法はいくつかありそうだった

* [ルールを使う](https://wiki.archlinux.jp/index.php/X_KeyBoard_extension#.E3.83.AB.E3.83.BC.E3.83.AB.E3.82.92.E4.BD.BF.E3.81.86)
* [キーマップを上書きする](https://wiki.archlinux.jp/index.php/X_KeyBoard_extension#.E3.82.AD.E3.83.BC.E3.83.9E.E3.83.83.E3.83.97.E3.82.92.E4.BD.BF.E3.81.86_.28.E9.9D.9E.E6.8E.A8.E5.A5.A8.2A.29)
* [新しいキーボードレイアウトを定義する](https://help.ubuntu.com/community/Custom%20keyboard%20layout%20definitions#Creating_a_new_layout_from_scratch)

自分の場合はキーマップの設定は[dotfiles](https://github.com/uyorum/dotfiles)で管理したいため2番目の方法を採用した。
ホームディレクトリ以下に追加のキーマップを定義するファイルを作成し、ログイン後に読み込むことにする。

## 設定したいキーマップ

以下のようにキーマップに変更したい。

* **Caps Lock** を **Control** へ
* **無変換** を **Control** へ
* **変換** を **Shift** へ
* (Apple Magic Keyboard) **英数** を **Control** へ
* (Apple Magic Keyboard) **かな** を **Control** へ

xkbのドキュメントをすべて読めば書き方がわかるのかもしれないが、よくわからなかったのでひとまずネット上の記事を参考にして書いた。

```shell
$ mkdir -p $HOME/.xkb/symbols
$ cat - <<EOF >$HOME/.xkb/symbols/custom
partial modifier_keys

xkb_symbols {
    key <CAPS> { [ Control_L, Control_L ] };
    modifier_map Control { <CAPS> };

    key <MUHE> { [ Control_L, Control_L ] };
    modifier_map Control { <MUHE> };

    key <HENK> { [ Shift_R ] };
    modifier_map Shift { <HENK> };

    key <HJCV> { [ Control_L, Control_L ] };
    modifier_map Control { <HJCV> };

    key <HNGL> { [ Shift_R ] };
    modifier_map Shift { <HNGL> };
};
EOF
```

CAPS、MUHEなどの文字列は

1. `xev`でkeycodeを調べて
1. `/usr/share/X11/xkb/keycodes/evdev`からkeycodeに対応する行を探す

で見つけることができる。

`Control_L, Control_L`と書いている箇所の2つめの`Control_L`はShiftを押しながそのキーを押したときもControlとして動作させるため。
後述するが期待通り動いていない。

上で定義した`custom`シンボルを上書きで読み込めばよい。現在のキーマップを調べて`custom`を追加する。

```shell
$ setxkbmap -print
xkb_keymap {
        xkb_keycodes  { include "evdev+aliases(qwerty)" };
        xkb_types     { include "complete"      };
        xkb_compat    { include "complete"      };
        xkb_symbols   { include "pc+jp+us:2+inet(evdev)"        };
        xkb_geometry  { include "pc(pc105)"     };
};
```

の場合は、

```shell
$ cat - <<EOF >$HOME/.keymap.xkb
xkb_keymap {
        xkb_keycodes  { include "evdev+aliases(qwerty)" };
        xkb_types     { include "complete"      };
        xkb_compat    { include "complete"      };
        xkb_symbols   { include "pc+jp+us:2+inet(evdev)+custom" };
        xkb_geometry  { include "pc(pc105)"     };
};
EOF
$ xkbcomp -I$HOME/.xkb $HOME/.keymap.xkb $DISPLAY 2>/dev/null
```

最後の`xkbcomp`で適用される。このコマンドをログイン時に自動で実行されるようにすればよい。

## 課題

* Shift+Caps+aでShift+Ctrl+aと同じように動作してほしいがうまくいかない
* サスペンドからの復帰後に元に戻ってしまう

## 参考
* [Custom keyboard layout definitions - Community Help Wiki](https://help.ubuntu.com/community/Custom%20keyboard%20layout%20definitions)
* [X KeyBoard extension - ArchWiki](https://wiki.archlinux.jp/index.php/X_KeyBoard_extension)
* [xkbでキーバインドを変更する（Ubuntu） | Honmushi blog](https://honmushi.com/2019/01/18/ubuntu-xkb/)
* [UbuntuでKeymapを入れ替えたり - sho2010 - Medium](https://medium.com/@sho2010/ubuntu%E3%81%A7keymap%E3%82%92%E5%85%A5%E3%82%8C%E6%9B%BF%E3%81%88%E3%81%9F%E3%82%8A-20fdbd5a47af)
