+++
slug = ""
tags = ["steamdeck","game"]
title = "SteamDeckのSSD換装とWindowsインストールしてディスク共有化まで"
date = "2023-08-27T02:35:50+09:00"
+++

AliexpressのセールでM.2 SSDがめちゃくちゃ安かったのでSteamDeckのSSDを換装してやります。  
OSが初期化されるのでついでにファイルシステムをbtrfs化してWindowsとディスクを共有できるようにします。  
また、関係ないですが原神がSteamOSで動くようになったと聞いたので試してみます。

<!--more-->

## SSD換装

購入したSSDは以下。Western DigitalのSN740(1TB)です。  
私が購入したときはセール中で8,700円でした。めちゃくちゃ安い。

[Western Digital WD SN740 SN530 M.2 2230 SSD 1TB 2TB 512GB NVMe PCIe Gen4 x4 for Microsoft Surface Pro X Surface Laptop 3 - AliExpress](https://www.aliexpress.com/item/1005005539645580.html)

換装手順は参考サイトの通りなので割愛。  
開始早々、筐体外側のネジをなめてしまいましたがマイナスドライバも使いなんとか外しました。  
内側下の2本のネジだけネジロック剤が付いているようなのでおそらく外しにくくなっています。今回なめてしまったネジもこのうちの１つです。
代わりのネジは早速Amazonで発注しました。到着までしばらくかかりますが、ネジ1本だけなら使用する分には問題ないので気長に待ちます。  

{{< affiliate asin="B0C3HFSXFG" title="ネジセットfor Steam deckゲーム機の裏蓋ねじ裏蓋交換フィリップスねじセットに適用 ネジロング4本ショート4本" >}}  
{{< affiliate asin="B08W1RXZB9" title="アネックス(ANEX) なめたネジはずし 精密用 ハンドル付 M1~2.6 No.3610-N" >}}

### 参考

[もしかして、全員SSD交換するべきかもしれないSteamDeck | yoshives](https://yoshives.com/steamdeck-ssd-upgrade/)  
[Steam Deck SSDの交換 - iFixit 修理ガイド](https://jp.ifixit.com/Guide/Steam+Deck+SSD%E3%81%AE%E4%BA%A4%E6%8F%9B/148989)

## btrfs化

btrfs化することでSteamOSとWindowsでディスク容量（ファイルシステム）を共有できます。  
[以前の記事](../steam-deck-windows-sd-card/)ではSDカードのパーティションを分割することでSteamOSとWindowsの双方でSDカードを使えるようにしました。
こちらはパーティションを分割して両者に割り当てる方法と違い、パーティション（ファイルシステム）自体は全体でひとつ（内蔵ディスクとSDカードは別々になります）で、両者で柔軟に容量を融通しあえるので使い勝手がいいです。
作業手順の中でSteamOSを初期化することになるので、SSD換装したこのタイミングで行ってしまいます。

こちらも手順は参考サイトの通り。
Windows用のパーティションは128GiB切り出しました。元の`/home`の容量から128Giを引いて1024をかけた容量（MiB）にパーティションを縮小します。

Windowsには以下のドライバやソフトウェアを入れておきます。

* [公式のデバイスドライバ一式](https://help.steampowered.com/ja/faqs/view/6121-ECCD-D643-BAA8)
* [WinBtrfs](https://github.com/maharmstone/btrfs)  
    Windows用のbtrfsドライバです  
    インストール後、再起動するとSteamOSの`/home`領域が見えるようになります。
* [SWICD](https://github.com/mKenfenheuer/steam-deck-windows-usermode-driver)  
    SteamDeckのコントローラがWindowsで使用できるようになります
* [Custom Resolution Utility](https://tonchikiroku.com/steamdeck-refresh-rate-40hz-how-to/)
    本来SteamDeck上のWindowsは60fps固定のところを変更できるようにします。  
    fpsを下げることで消費電力削減を狙っています。

参考サイトで紹介されているRefindの導入はいったん見送りました。SteamOSアップデート時の対応がやや面倒そうだったので。  
UEFIで起動の優先順位を変えればSteamOSをデフォルトにできそうなので後日調査することにします。

### 参考

[SteamDeckにWindowsを入れてデュアルブートにしてみた（BTRFS） #SteamDeck｜小判](https://note.com/asami_konno/n/n9fdb07744546#e69be92a-8df1-4f72-8b86-d64c51a79382)  
[Philipp Richter / SteamOS Btrfs · GitLab](https://gitlab.com/popsulfr/steamos-btrfs)  
[mKenfenheuer/steam-deck-windows-usermode-driver: A windows usermode controller driver for the steam deck internal controller.](https://github.com/mKenfenheuer/steam-deck-windows-usermode-driver)

## SteamOSで原神を動かす

SteamDeck発売直後はSteamOSで原神は動かなかったのですが、その後のSteamOS（Proton）のアップデートにより動くようになったそうです。  
SteamDeckにWindowsをインストールしてWindowsで原神を動かしたり、原神に独自パッチを当ててSteamOS上で動かす記事が見つかりますが、そういった回避は不要で普通にSteamOSで原神を動かします。  
ただし原神はSteamにはないので少しインストール手順が複雑です。

手順は[参考サイト](https://time-gadget.com/2023/07/27/%E3%80%90%E7%94%BB%E5%83%8F%E3%81%A7%E8%A7%A3%E8%AA%AC%E3%80%91steam-deck%E3%81%AEsteam-os%E3%81%A7%E5%8E%9F%E7%A5%9E%E3%82%92%E3%82%A4%E3%83%B3%E3%82%B9%E3%83%88%E3%83%BC%E3%83%AB%E3%81%99%E3%82%8B/)を参照。
この方は内蔵ディスクに原神をインストールする方法も[記事](https://time-gadget.com/2023/08/17/%E3%80%90%E7%94%BB%E5%83%8F%E3%81%A7%E8%A7%A3%E8%AA%AC%E3%80%91steam-deck%E3%81%AEsteam-os%E3%81%A7%E5%8E%9F%E7%A5%9E%E3%82%92%E3%82%A4%E3%83%B3%E3%82%B9%E3%83%88%E3%83%BC%E3%83%AB%E3%81%99%E3%82%8B-2)にされていますが、SDカードにインストールする手順の方で原神のインストール先をデフォルト（Cドライブ）のままインストールを進めて問題なくインストールできました。

### バイナリの探し方

参考サイトではSDカードに原神をインストールしていますが、今回はデフォルトのまま（Cドライブ=内蔵SSD）
にインストールするのでインストールした原神のバイナリの探し方が異なります。
デスクトップモードでターミナルを起動し以下のコマンドで見つけることができます。

``` shell
find .local -type f -name launcher.exe
```

原神インストーラをSteamに登録していると思いますので、それを編集してlauncher.exeのパスへ変更してやるのが楽です。

### 動かしてみて

Windowsよりパフォーマンスはやや落ちるかなという印象です。画質設定「中」だと頻繁にフレームレートが落ちるので「低」へ変更したほうがよいです。数日遊んでみましたが動作がおかしいところは特になかったのでしばらく常用してみようと思います。  
ただしSteamOSのアップデートで動かなくなる可能性があるのでWindowsの方にもインストールしておいた方がいいかも。

読み込み速度はWindowsで原神をSDカードにインストールしていた場合と体感それほど変わりませんでした。残念。

### 参考

[【画像で解説】Steam Deckのsteam OSで原神をインストールする方法（microSD編） | ガジェットの時間](https://time-gadget.com/2023/07/27/%E3%80%90%E7%94%BB%E5%83%8F%E3%81%A7%E8%A7%A3%E8%AA%AC%E3%80%91steam-deck%E3%81%AEsteam-os%E3%81%A7%E5%8E%9F%E7%A5%9E%E3%82%92%E3%82%A4%E3%83%B3%E3%82%B9%E3%83%88%E3%83%BC%E3%83%AB%E3%81%99%E3%82%8B/)

私が使っているSDカードはこちら↓
{{< affiliate asin="B08927YRXX" title="SanDisk マイクロSD 512GB サンディスク Extreme microSDXC A2 SDSQXA1-512G-GN6MN SD変換アダプターなし 海外パッケージ品" >}}
