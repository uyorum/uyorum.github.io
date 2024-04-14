+++
slug = ""
tags = ["cloudflare"]
title = "EdgeRouter XをCloudflare Tunnelに接続する"
date = "2023-01-03T20:17:19+09:00"
+++

[前回](../cloudflare-zero-trust-warp/)の続き。  
WARPとCloudflare Tunnelを組み合わせて自宅をインターネットへ公開することなく自宅VPNのようなことを実現しようとしているところです。

<!--more-->

## 手順

機種は違いますが[GitHub](https://github.com/cloudflare/cloudflared/issues/19)にCloudflredを独自に導入する手順を公開されている方がいました。
基本的な流れはこの通りで、[ドキュメント](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/tunnel-guide/)を見つつ進めました。

ER-X上で`cloudflared`というバイナリを実行することになります。
ER-XはLinuxベースではありますがCPUがMIPSアーキテクチャです。公式ではMIPS向けのバイナリは配布されていないので自分でビルドする必要があります。

### Cloudflareにドメインを登録

おそらくここが一番ハードルが高いです。
[ドキュメント](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/tunnel-guide/local/)に書かれている通り、はじめにドメインをCloudflareに登録する必要があります。

ここで登録するドメインはサブドメインではダメで、かつドメインの管理権限を持っている必要があります。(NSレコードをCloudflareのDNSサーバに向ける必要がある)
手順は以下のページの通り。NSレコードを設定する手順はドメインを購入したレジストラによるのでここでは省略します。

[Add a site · Cloudflare Fundamentals docs](https://developers.cloudflare.com/fundamentals/get-started/setup/add-site/)


### cloudflaredをビルド

cloudflaredはGoで書かれているので、Goが入った環境があればかんたんにMIPS向けにクロスコンパイルができます。
自分は適当なLinux環境を用意してクロスコンパイルしました。
`GOARCH=mips`でビルドしたところ動かなかったので`GOARCH=mipsle`を指定しています。

``` shell
$ git clone https://github.com/cloudflare/cloudflared.git
$ cd cloudflared/cmd/cloudflared
$ GOOS=linux GOARCH=mipsle go build
$ file cloudflared
cloudflared: ELF 32-bit LSB executable, MIPS, MIPS32 version 1 (SYSV), statically linked, Go BuildID=q_P-LGbj9vqwTTHowwBy/7Tk5tV1mPGz9w77J1-Ua/Hfb51RmrmdHravgslRT8/GYp4QzVANZXUOcLjO8Gr, not stripped
```

`cloudflared/cmd/cloudflared/cloudflared`にバイナリが出来上がっているので、これをER-Xの`/usr/local/sbin/`に置いておきます。(ディレクトリは新たに作成)

### ログイン

ここから先はER-X上で実行します。  
はじめにバイナリに実行権限を設定します。

``` shell
$ sudo -i
# chown root:root /usr/local/sbin/cloudflared
# chmod 755 /usr/local/sbin/cloudflared
```

次にcloudflaredでCloudflareにログインし証明書をダウンロードします。
コマンドを実行するとURLが表示されるので、PCでアクセスしてログインするという流れです。

``` shell
# cloudflared tunnel login
Please open the following URL and log in with your Cloudflare account:

https://dash.cloudflare.com/argotunnel?callback=https%3A%2F%2Flogin.cloudflareaccess.org%2FXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXx%3D

Leave cloudflared running to download the cert automatically.
2023-01-03T09:06:42Z INF Waiting for login...
```

ログインするとドメインを選択する画面が表示されるので、先ほど登録したドメインを選択し「承認」します。

![select_domain](/cloudflare-tunnel-edgerouter-x/select_domain.jpg)

ER-Xに戻ると証明書を保存しコマンドが終了しています。
関連ファイルは`/etc/cloudflared`に集めたかったので移動しておきます。

``` shell
You have successfully logged in.
If you wish to copy your credentials to a server, they have been saved to:
/root/.cloudflared/cert.pem
# mkdir /etc/cloudflared
# mv /root/.cloudflared/cert.pem /etc/cloudflared
# rm -rf /root/.cloudflared
```

cloudflaredは設定ファイルを`~/.cloudflared`、`/etc/cloudflared`、`/usr/local/etc/cloudflared`の順に探してくれるので移動させても問題ありません。

[Useful terms · Cloudflare Zero Trust docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/tunnel-useful-terms/#default-cloudflared-directory)

### Tunnelの作成と設定

続いてTunnelを作成していきます。Tunnel名は「Home」にします。

``` shell
# cloudflared tunnel create Home
Tunnel credentials written to /etc/cloudflared/65b71b5e-7356-4f1e-90bc-88f9a9b8db7b.json. cloudflared chose this file based on where your origin certificate was found. Keep this file secret. To revoke these credentials, delete the tunnel.

Created tunnel Home with id 65b71b5e-7356-4f1e-90bc-88f9a9b8db7b
```

Tunnelの接続に使われる認証情報が`/etc/cloudflared/*.json`として保存されます。

次にcloudflaredの設定ファイルを作成します。

``` shell
# vi /etc/cloudflared/config.yml
# cat /etc/cloudflared/config.yml
tunnel: 65b71b5e-7356-4f1e-90bc-88f9a9b8db7b
credentials-file: /etc/cloudflared/65b71b5e-7356-4f1e-90bc-88f9a9b8db7b.json
warp-routing:
  enabled: true
```

### cloudflaredを起動

恒久的にはデーモン化が必要ですが、ひとまず手で実行します。

``` shell
# cloudflared --config /etc/cloudflared/config.yml tunnel run
...
2023-01-03T13:17:07Z INF Connection 556e7512-0b96-4f0d-9232-b7eab07a76a4 registered with protocol: quic connIndex=0 ip=x.x.x.x location=KIX
2023-01-03T13:17:07Z INF Connection c05977a3-78f8-4edd-9a31-e21e8932e6a7 registered with protocol: quic connIndex=1 ip=x.x.x.x location=NRT
2023-01-03T13:17:09Z INF Connection cf942eca-718f-46ed-9f4d-1bc7cd839f0f registered with protocol: quic connIndex=2 ip=x.x.x.x location=KIX
2023-01-03T13:17:09Z INF Connection ddc90b1d-70ab-45b0-93ba-5fd482f68be2 registered with protocol: quic connIndex=3 ip=x.x.x.x location=NRT
```

いろいろ表示されますがどうやら接続されたようです。  
Cloudflare Zero TrustのWeb画面でもStatusがHEALTHYと表示されています。

![tunnel_status](/cloudflare-tunnel-edgerouter-x/tunnel_status.jpg)

いったん以上でTunnelの接続まではできました。WARPクライアントからER-X側のLANにアクセスするにはまだいろいろと設定が必要ですがER-X側の残りの設定をしていきます。

### cloudflaredをデーモン化

[Run as a service on Linux · Cloudflare Zero Trust docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/tunnel-guide/local/as-a-service/linux/)

cloudflaredには自身をサービスとしてインストールすることができるようなのでこの機能を使います。
ER-X自身もSystemdが動いているのでこの仕組みに乗っかればよさそうです。

``` shell
# cloudflared service install
2023-01-03T13:37:04Z INF Using Systemd
2023-01-03T13:37:07Z INF Linux service for cloudflared installed successfully
```

確認したところ以下の3つのUnitがインストールされたようです。

* /etc/systemd/system/cloudflared.service
* /etc/systemd/system/cloudflared-update.service
* /etc/systemd/system/cloudflared-update.timer

cloudflared-update.{service,timer}はcloudflared自身を日次で更新するUnitですが、ER-X向けは自分でビルドしないといけないので意味がありません。この2つは削除します。

``` shell
# rm /etc/systemd/system/cloudflared-update.service
# rm /etc/systemd/system/cloudflared-update.timer
# systemctl daemon-reload
# systemctl enable cloudflared
# systemctl start cloudflared
# systemctl status cloudflared
* cloudflared.service - cloudflared
   Loaded: loaded (/etc/systemd/system/cloudflared.service; enabled; vendor preset: enabled)
   Active: active (running) since Tue 2023-01-03 22:37:07 JST; 13min ago
 Main PID: 7846 (cloudflared)
   CGroup: /system.slice/cloudflared.service
           `-7846 /usr/local/sbin/cloudflared --no-autoupdate --config /etc/cloudflared/config.yml tunnel run
```

デーモン化はこれでよさそうです。

### TunnelをWeb UI管理に変更

今回のTunnelはコマンドで作ったため、Cloudflare Zero TrustのWeb UIでは変更が行えないようになっています。
考え方次第ですが、個人的にこのままでは不便なのでWeb UIから管理できるようにしておきます。
一度これを行うとCLIでは変更できなくなるので注意です。

Access > Tunnels からTunnelのConfigureをクリックし「Start migration」へ進みます。
出てきたダイアログをCofirmしていけばmigrateが完了します。

いったん以上です。WARPクライアントからLANにアクセスするための設定は別の記事にまとめます。

## 余談

実は我が家のEdgeRouterはグローバルアドレスを持っていません。(光回線のHGWが持っている)  
EdgeRouterはNAPTでインターネットへ出ていく構成なんですが、そのような構成でも全く問題なくTunnelにつなげることができました。  
マンションに付属のインターネット回線等、各戸にグローバルアドレスが割り当てられない状況でも自宅につながるVPN網を構築したり、自宅のサーバをインターネットへ公開することができるので、そういう状況では特に便利ですね。

私も一時期そのようなマンションに住んでいたのですが、その時は[こんなこと](../publish-with-openvpn-1/)をやってました。
それがサービスで、しかも無料で実現できるのは素晴らしいです。

## 参考

* [Via the command line · Cloudflare Zero Trust docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/tunnel-guide/local/)
* [notes for installing on a Ubiquiti Edgerouter 4 · Issue #19 · cloudflare/cloudflared](https://github.com/cloudflare/cloudflared/issues/19)
* [Run as a service on Linux · Cloudflare Zero Trust docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/tunnel-guide/local/as-a-service/linux/)

{{< affiliate asin="B00YFJT29C" title="Ubiquiti EdgeRouter X Advanced Gigabit Ethernet Routers ER-X 256MB Storage 5 Gigabit RJ45 ports by Ubiquiti" >}}
