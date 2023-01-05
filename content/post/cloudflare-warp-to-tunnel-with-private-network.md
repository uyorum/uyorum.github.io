+++
slug = ""
tags = ["cloudflare"]
title = "Cloudflare Zero TrustのWarpクライアントからTunnel側のホストへアクセスする(Private network)"
date = "2023-01-05T00:41:04+09:00"
+++

[前回](../cloudflare-tunnel-edgerouter-x/)の続き。  
[前々回](../cloudflare-zero-trust-01/)と組み合わせてWARPクライアントとTunnelが用意できたので、当初の目的であるWARPクライアントからイントラネットへアクセスする設定を行っていきます。

<!--more-->


## 2つの方式

Cloudflare Zero TrustのVPN網からTunnel(cloudflared)側のサービスへアクセスする際、「IPベース」と「DNSベース」の2つの方式があります。
Cloudflareのドキュメントでは前者は「Private networks」、後者は「Public hostnames」と呼ばれています。

簡単のため今回は前者のPrivate networksの方式を採用します。

## 手順

WARPクライアントとTunnelはそれぞれすでに接続済であるとします。


### Tunnel側のCIDRを登録

はじめにTunnelの先にあるネットワークのCIDRを教えてやります。

Cloudflare Zero TrustのWebにログインしAccess > Tunnelsから対象のTunnelのConfigureをクリックします。  
Private Networkを表示し「Add a private network」からCIDRを入力します。通常はLANのCIDRになります。

### Split Tunnelを設定

VPNで一般的なSplit Tunnelですが、WARPクライアントでも実装されています。
デフォルトではRFC 1918に基づくプライベートアドレス宛のパケットはVPN網ではなくネイティブのネットワークへ流すようになっています。  
このままだと目的の通信ができないので上で登録したCIDR宛はVPN網へ流すように設定する必要があります。

Settings > WARP Client > Device settingsと辿って、今回のWARPクライアントで使うプロファイルのConfigureをクリックします。(初期状態では「Default」というプロファイルしかないと思います)

一番下の「Split Tunnels」が目的のメニューですが、最初にSplit Tunnelのモード（ExcludeとInclude）を理解する必要があります。

|モード|動作|
|:--|:--|
|Exclude|デフォルト。ここで指定した宛先*以外*のすべてのトラフィックをVPN網へ流す|
|Include|ここで指定した宛先のトラフィックのみVPN網へ流す|

どちらを選ぶかはポリシー次第かと思いますが、Policyなどでデバイスをより厳格に管理したい場合はExclude、そうでない場合はIncludeを選択すると良いと思います。

今回はIncludeを選択しました。ExcludeからIncludeへ変更しようとすると既存のエントリをすべて消す旨の警告が表示されますが、そのまま進みます。  
Includeへ変更したらその右の「Manage」をクリックします。  
ここでPrivate NetworkのCIDRを登録してやればいいのですが、Includeの場合はそれに加えていくつかのドメインを登録することが推奨されています。

[Split Tunnels · Cloudflare Zero Trust docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-devices/warp/exclude-traffic/split-tunnels/#cloudflare-zero-trust-domains)

最終的に以下の3つのエントリを登録しました。

|Type|Value|
|:--|:--|
|IP Address|Private Networkに登録したCIDR|
|Domain|Team名.cloudflareaccess.com (Teams名は[前々回](../cloudflare-zero-trust-01/)設定しました)|
|Domain|*.Cloudflareに登録したドメイン (ドメインは[前回](../cloudflare-tunnel-edgerouter-x/)設定しました)|

### WARPクライアントから通信してみる

以上の設定で完了です。
WARPクライアントからLAN上のサービスにアクセスできることを確認しましょう。

ちなみにサーバから見た送信元アドレスはcloudflaredを導入したER-XのIPになっていました。  
ER-Xで確認したところTCPセッションもER-Xとサーバ間で確立されているようでした。

以上

## 参考

* [Connect private networks · Cloudflare Zero Trust docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/private-net/connect-private-networks/)
* [Split Tunnels · Cloudflare Zero Trust docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-devices/warp/exclude-traffic/split-tunnels/#add-an-ip-address)

{{< affiliate asin="4297126257" title="ゼロトラストネットワーク[実践]入門" >}}
