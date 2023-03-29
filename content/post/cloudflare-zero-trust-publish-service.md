+++
slug = ""
tags = ["cloudflare"]
title = "Cloudflare Zero Trustでイントラネット上のサービスをインターネットへ公開する"
date = "2023-03-26T16:08:05+09:00"
+++

自宅で動いているHome AssistantをGoogle Assistantから操作したかったのでインターネットへ公開することにした。

<!--more-->

## 前提

* イントラネット上にcloudflaredを導入しTunnelを接続済みであること  
    手順は[以前の記事](../cloudflare-tunnel-edgerouter-x/)で説明しています
* cloudflaredから対象のイントラサービスへアクセスできること
* プロトコルはHTTP(S)であること

## 手順

1. Zero TrustのWeb UIからTunnelの一覧画面へアクセス（Access > Tunnels）
1. 公開したサービスへつながるTunnelを選択し、Configure
1. Public Hostnameタブへ移動
1. [Add a public hostname]をクリック
1. 公開する際のサブドメインやサービスのURLを入力する

これだけで、サービスを公開することができる。

ドキュメントにはCloudflare DNSでレコードを作成する手順も書かれているが、上の手順だけでレコードも自動で作成された。

## 参考

[DNS record · Cloudflare Zero Trust docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/routing-to-tunnel/dns/)
