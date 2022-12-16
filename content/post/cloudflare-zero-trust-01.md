+++
slug = ""
tags = ["cloudflare"]
title = "Cloudflare Zero TrustにAndroidを接続するまで（最短経路）"
date = "2022-12-16T21:18:59+09:00"
+++

Cloudflare Zero Trustを自宅やクラウドを繋げるVPN代わりに使いたかったのでまずはAndroid端末を接続できるようにする。

<!--more-->

## 簡単に解説

[「Cloudflare Zero Trust」 で組織のゼロトラストネットワークを構成する](https://zenn.dev/hiroe_orz17/articles/67f63b9c7a9da5)

Cloudflare Zero Trustの概要はこのあたりを読むとして、ざっくり言うと
デバイス（スマホやPC）やルータからCloudflareのサーバへVPNを接続することでひとつの仮想ネットワークを構成することができる。
従来のような、自分でVPNサーバを用意してインターネットへ公開したりする必要がない。

それだけではなく、Cloudflare上で用意されているDNSサーバをデバイスに参照させることによって有害なサイトをDNSレベルでブロックしたり、
HTTPSをCloudflareで復号して通信を検査したりすることができる。

## 前提

* Cloudflareのアカウントを開設済みであること

## 用語の解説

けっこう用語が独特で理解するのに手こずった。説明はあまり正確でないかもしれない

* Tunnel  
    CloudflareへVPNを接続する際の構成は2通りある。  
    TunnelはLAN内のサービスをインターネットへ公開したり、Cloudflareのネットワークに接続されたデバイスからアクセスしたりする際のルータのような役割として動作する。
    LAN内のホストからCloudflareの方向でトンネルを貼りに行くのでVPNサーバのようなものをインターネットに公開する必要はない。
    `cloudflared`という名前のバイナリを使う。
* WARP  
    PCやスマホ向けに提供されるVPN接続アプリ。各OS向けに提供されている。
* Gateway  
    Cloudflare経由の通信のポリシーを定義する場所。DNSやHTTP、IPのレイヤでポリシーを設定できる。

## 手順

[Get started · Cloudflare Zero Trust docs](https://developers.cloudflare.com/cloudflare-one/setup/)  
基本的にこのチュートリアルに従って設定していけばうまくいく。

1. [Cloudflare Zero Trustのダッシュボード](https://one.dash.cloudflare.com)へアクセス
1. Team名を設定する  
    テナント（アカウント）を特定するのに使われる一意な名前。WARPクライアントでVPNを接続する際の認証の際に入力したりする。  
    ここで設定した値はあとから変更可能。
1. 課金プランを選択する  
    とりあえず無料プランを選択する。  
    無料プランの場合も支払い方法の設定は必要。自分はPaypalを選択
1. 以上でダッシュボードが表示される
1. WARPクライアントが接続する際の認証方法を設定する (Setting > Authentication > Login methods)  
    デフォルトで「One-time PIN」という認証方法が有効になっている。  
    これは入力したメールアドレスにPINが届き、アプリへ入力するという認証方法。ひとまずはこの認証方法で十分

    ![login_method.jpg](/cloudflare-zero-trust-01/login_method.jpg)

1. Device enrollment permissionsを定義する (Settings > WARP Client > Device enrollment permissions)  
    Device enrollment permissionsとは、いわゆるログイン時の認可の部分。  
    認証で取得した情報を使って、ログインを許可するための条件を定義する。  
    とりあえずは自分のメールアドレスだけを許可するようなルールを定義する。

    |項目|値|
    |:--|:--|
    |Rule name|login（なんでもよい）|
    |Rule ction|Allow|
    |Selector|Emails|
    |Value|自分のメールアドレス|

    ![device_enrollment_permissions.jpg](/cloudflare-zero-trust-01/device_enrollment_permissions.jpg)

1. Androidに[WARPアプリ](https://play.google.com/store/apps/details?id=com.cloudflare.onedotonedotonedotone)をインストール
1. アプリを起動
1. 設定 > Gateway を選択
1. 設定 > アカウント > Cloudflare Zero Trustにログイン
1. 組織名は上で定義したTeam名を入力
1. Cloudflare Accessというページへ飛ぶのでメールアドレスを入力し[Send me a code]
1. 届いたメールのリンクへ飛ぶか、PINを先ほどのページへ入力
1. ログインが完了する
1. VPNプロファイルをインストールしVPNを接続

![warp_connected.jpg](/cloudflare-zero-trust-01/warp_connected.jpg)

ダッシュボードのAnalytics > Accessからも接続されていることがわかる。

## 参考

* [About Cloudflare WARP · Cloudflare Zero Trust docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-devices/warp/)
* [「Cloudflare Zero Trust」 で組織のゼロトラストネットワークを構成する](https://zenn.dev/hiroe_orz17/articles/67f63b9c7a9da5)
