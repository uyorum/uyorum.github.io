+++
date = "2018-12-15T18:19:48+09:00"
slug = ""
tags = ["",""]
title = "NginxでLet's Encryptの証明書を扱う"

+++

自分なりのベストな設定をメモ

# 環境

``` shell
$ cat /etc/redhat-release
CentOS Linux release 7.6.1810 (Core)
$ rpm -q certbot nginx
certbot-0.29.1-1.el7.noarch
nginx-1.12.2-2.el7.x86_64
```

# 証明書の新規発行
WebサーバにNginxを使用しているような環境で，Certbotを使って(更新を含む)証明書を発行するには以下
のような方法が考えられる．

|Plugin|概要|
|:-:|:--|
|Webroot|指定したディレクトリにトークンを配置し，任意のWebサーバ(今回の環境ではNginxを使うことになるだろう)で公開することで認証を行う|
|Nginx|Nginxを使用して認証を行う．また取得した証明書を使うようNginxを自動で設定する|
|Standalone|Certbot自身がHTTPをListenして認証を行う|
|DNS|取得したい証明書のドメインのTXTレコードにトークンを登録することで認証を行う|

DNS Pluginを使えば認証のためにサーバを設定する必要がなくなるためベストなのだと思うが，自分が使用しているDNSサービス(No-IP)ではTXTレコードを設定できないため却下．Nginxの設定は自分で管理したいためNginx Pluginも却下．
Webroot Pluginを使って証明書を新規発行する場合，一度Nginxを(ほぼ)デフォルトの設定で起動させて証明書を取得後，証明書を使うようNginxの設定を変更してからNginxを再起動するという面倒な手順になる．そのため，証明書の新規発行はNginxを起動させる前にStandalone Pluginで行う(既にNginxが起動していた場合は80番ポートが競合することになるためうまくいかない)．

``` shell
# certbot certonly --standalone -d <DOMAIN NAME> -m <MAIL ADDRESS> --agree-tos -n
```

これにより以下のファイルが作成される

* サーバ証明書…/etc/letsencrypt/live/<DOMAIN NAME>/fullchain.pem
* 秘密鍵…/etc/letsencrypt/live/<DOMAIN NAME>/privkey.pem

これらを使用するようNginxを設定すればよい．

# 証明書の更新

以降はNginxが起動しているはずだ．Nginxが80番ポートをListenしないよう設定しているならよいが，自分の環境ではHTTPをHTTPSへリダイレクトするようにしたかったためNginxは80番ポートもListenしている．
そのため証明書の更新ではStandalone Pluginは使えない．[^1]
そこで証明書の更新はWebroot Pluginと既に起動中のNginxを使うことにする．Nginxにはそのための設定をあらかじめ入れておく．[^2]

``` nginx
server {
  listen 80;
  listen [::]:80;
  server_name <DOMAIN NAME>;

  # Load configuration files for the default server block.
  include /etc/nginx/default.d/*.conf;

  location /.well-known/acme-challenge {
    default_type "text/plain";
    root /var/www/certbot;
  }

  location / {
    return 301 https://$server_name$request_uri;
  }
}
```

`location /.well-known/acme-challenge`を`location /`より前に書いておくことで，`http://<DOMAIN NAME>/.well-known/acme-challenge/`以下へのアクセスはリダイレクトされずに`/var/www/certbot`をDocumentRootとしてレスポンスを返すようになる．

証明書の更新時は`/var/www/certbot`以下にトークンを保存するよう指定してCertbotを起動させればよい．(このディレクトリはあらかじめ作成しておく必要がある)

``` shell
# mkdir -p /var/www/certbot
# certbot renew --webroot -w /var/www/certbot --post-hook '/usr/bin/systemctl restart nginx'
```

追記：自分の環境では`/var/www`をここで作成したせいか，SELinuxのコンテキストが`unconfined_u:object_r:var_t:s0`になってしまいNginxから参照できなくなってしまった．
そのためコンテキストの修正が必要だった．

``` shell
# restorecon -R /var/www
```

(追記終わり)

自分の場合はanacronを使って週次で実行するようにした．証明書の有効期限が1ヶ月を切っていた場合のみ証明書が更新される．

``` shell
# cat <<'EOF' >/etc/cron.weekly/certbot
#!/bin/bash

/usr/bin/certbot renew --webroot -w /var/www/certbot --post-hook '/usr/bin/systemctl restart nginx'
# chmod +x /etc/cron.weekly/certbot
```

以上．

# 参考
[User Guide — Certbot 0.29.0.dev0 documentation](https://certbot.eff.org/docs/using.html)

[^1]: Certbotを起動する前にNginxを停止すればできないこともないが，当然その間はWebサーバにアクセスできない
[^2]: ここではHTTPSのための設定は割愛する
