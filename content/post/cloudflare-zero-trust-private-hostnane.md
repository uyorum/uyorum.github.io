+++
slug = ""
tags = ["cloudflare"]
title = "Cloudflare Zero TrustのWarpクライアントからTunnel側のホストへアクセスする(ホスト名ベース)"
date = "2023-01-06T19:03:24+09:00"
+++

[前回](../cloudflare-zero-trust-private-ip/)の続き。
前回はアドレスでアクセスしましたが今回はイントラのホスト名でアクセスできるようにします。

<!--more-->

## 前提

* cloudflaredとWARPがセットアップ済みでアドレスベースでイントラへアクセスできていること
* cloudflaredのバージョンが2021.12.3以上であること

## 手順

[Private hostnames and IPs · Cloudflare Zero Trust docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/private-net/private-hostnames-ips/)

基本的に手順の通りに進めていきます。

### UDPサポートを有効にする

1. Cloudflare Zero TrustのダッシュボードからSettings > Networkと進んでいきます
1. FirewallセクションのProxyという項目のUDPにチェックを入れます

これによりUDPパケットもTunnelへフォワードしてくれるようになります。  
ドキュメントでは説明されていませんがDNSのリクエストをイントラネット上のDNSサーバへフォワードするためなのかと思います。

### ローカルドメインフォールバックのエントリを登録する

イントラ上のホスト名の名前解決をイントラ上のDNSサーバで行うための設定を行います。

1. Settigs > WARP Clientと進みます
1. プロファイルのconfigureをクリックし設定画面を開きます
1. 下の方のLocal Domain FallbackのManageをクリックします
1. イントラネットのドメインとそれを名前解決できるDNSサーバのアドレスを入力しSave domainをクリックします  
    DNSサーバは複数指定することが可能です。複数指定した場合はすべてのDNSサーバへリクエストし最も早いレスポンスが使用されます

### cloudflaredの設定を更新

cloudflaredの設定ファイルに`protocol: quic`を追加してcloudflaredを再起動します。

``` yaml
tunnel: 65b71b5e-7356-4f1e-90bc-88f9a9b8db7b
credentials-file: /etc/cloudflared/65b71b5e-7356-4f1e-90bc-88f9a9b8db7b.json
warp-routing:
  enabled: true
protocol: quic
```

### 確認

以上で設定は終わりです。  
WARPクライアントが入った端末からイントラ上のホスト名でサーバにアクセスできるはずです。

## 参考

* [Private hostnames and IPs · Cloudflare Zero Trust docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/private-net/private-hostnames-ips/)

{{< affiliate asin="4297126257" title="ゼロトラストネットワーク[実践]入門" >}}
