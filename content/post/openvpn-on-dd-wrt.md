+++
Categories = []
Tags = ["OpenVPN", "DD-WRT"]
title = "DD-WRTでOpenVPNの設定"
date = "2015-03-29T20:56:18+09:00"
aliases = ["/blog/openvpn-on-dd-wrt/"]

+++

色々はまったのでメモ。

<!--more-->

## 参考

* [easy-rsa 3 で認証局を構築する « yamata::memo](http://yamatamemo.blogspot.jp/2014/01/easy-rsa-3.html)
* [DD-WRTとiPhone5sでVPNの構築（OpenVPN）｜チョコボール室井の報告書](http://ameblo.jp/chocoball-muroi/entry-11788301407.html)

## 認証局の設置~クライアント証明書の作成

[easy-rsa](https://github.com/OpenVPN/easy-rsa)を使用する．使い方は[ここ](http://yamatamemo.blogspot.jp/2014/01/easy-rsa-3.html)を参考に．
後から気づいたが[vpnux PKI Manager](http://www.openvpn.jp/vpnux-pki/)なんていうGUIツールが公開されていた．これを使えば楽にできるかも．

## DD-WRTの設定

### OpenVPNサーバの設定

Services -> VPNから

Key|Value
:-|:-
OpenVPN|Enable
Start Type|WAN Up
Config as|Server
Server mode|Router (TUN)
Network|10.0.1.0
Netmask|255.255.255.0
Port|11194
Tunnel Protocol|TCP
Encryption Cipher|AES-256-CBC
Hash Algorithm|SHA256
Advanced Options|Enable
TLS Cipher|None
LZO Compression|Yes
Redirect default Gateway|Disable
Allow Client to Client|Disable
Allow duplicate cn|Disable
Tunnel MTU setting|1400
Tunnel UDP Fragment|-
Tunnel UDP MSS-Fix|Disable
CCD-Dir DEFAULT file|-
Static Key|-
PKCS12 Key|-
Public Server Cert|サーバ証明書の内容を転載
CA Cert|CA証明書の内容を転載
Private Server Key|サーバの秘密鍵の内容を転載
DH PEM|DHパラメータの内容を転載
Additional Config|push "route 10.0.0.0 255.255.255.0"
TLS Auth Key|-
Certificate Revoke List|-

<br>
いくつか説明

* Network, Additional Configについて  
自宅のLANは10.0.0.0/24で作成している．OpenVPNで接続したクライアントはそれとは別のセグメント(10.0.1.0/24)に配置することにする．(自動でサーバのIPアドレスは10.0.1.1になる)

接続してきたクライアントへ自宅LAN宛のルーティングを追加するためにAdditional Configに「push ~行」を追加している．

* Portについて  
セキュリティのことを考えてデフォルトのポートから変更する．後に設定するclient.ovpnやポート転送の設定値もここの値にそろえる．

* Tunnel Protocolについて  
なぜかUDPだとクライアントから接続できなかったためTCPにする．

設定が完了したらApply Settingsをクリック．

### ポートフォワーディングの設定

OpenVPNの設定を書けばWAN側ポートでも待ち受けてくれるものと思っていたがそうではないみたい．
別途ポートフォワーディングの設定をする必要があった．ここで一番つまった．

NAT/QoS -> Port Forwardingから

Application|Protocol|Source Net|Port from|IP Address|Port to|Enable
:-|:-|:-|:-|:-|:-|:-
OpenVPN(任意の文字列)|TCP|0.0.0.0/0|11942|10.0.1.1|11942|チェックを入れる

## クライアントの設定

インストール方法は省略

* client.ovpn

コメントを除けば以下の内容

    client
    dev tu
    proto tcp
    remote <OpenVPNサーバのホスト名またはIPアドレス> 11194
    resolv-retry infinite
    nobind
    persist-key
    persist-tun
    ca <CA証明書のファイル名>
    cert <クライアント証明書のファイル名>
    key <クライアント秘密鍵のファイル名>
    remote-cert-tls server
    cipher AES-256-CBC
    comp-lzo
    verb 3
    auth sha256

証明書と秘密鍵はclient.opvnと同じディレクトリ(Windowsの場合はC:\Program Files\OpenVPN\config)に置けばよい．
なお証明書と秘密鍵はファイル名を書くかわりに以下のように.opvnに内容を直接書くこともできるみたい．1ファイルで完結するからこちらの方がいいかも．

    <ca>
    -----BEGIN CERTIFICATE-----
    略
    -----END CERTIFICATE-----
     
    </ca>
     
    <cert>
    -----BEGIN CERTIFICATE-----
    略
    -----END CERTIFICATE-----
     
    </cert>
     
    <key>
    -----BEGIN PRIVATE KEY-----
    略
    -----END PRIVATE KEY-----
     
    </key>

あとはクライアントから接続するだけ．
