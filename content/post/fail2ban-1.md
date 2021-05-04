+++
date = "2019-07-04T20:32:07+09:00"
slug = ""
tags = ["",""]
title = "fail2banでBotからsshdとNginxを守る"
aliases = ["/blog/fail2ban-1/"]

+++

久しぶりにfail2banを使ったら設定方法を調べるのに苦戦したのでメモ

<!-- more -->

# やりたいこと
* 以下のようなアクセスを行なったIPアドレスをBotとみなす
    * SSHで認証に失敗したアクセスの送信元アドレス
    * HTTPやHTTPSでよくある攻撃対象のパスへアクセスしてきた送信元アドレス
* BotとみなしたIPアドレスからのアクセスは以後すべてのポートでDROPするようにする
* 一度BotとみなしたIPアドレスは永久にブロックする

# 環境

``` shell
# cat /etc/redhat-release
CentOS Linux release 7.6.1810 (Core)
# yum list fail2ban
fail2ban.noarch     0.9.7-1.el7     @epel
```

# 情報源

いろいろ調べたが結局`man`が一番参考になるし信用できる．

``` shell
$ man fail2ban
$ man jail.conf
$ man ipset
```

# インストール

``` shell
# yum install -y fail2ban
```

# 設定ファイル類
設定ファイルは`/etc/fail2ban`に集まっている．

* fail2ban.conf  
    fail2ban全般の設定を書く．変更するとしたらログレベルやログファイルのパスくらい．
* jail.conf  
    filterとactionの組み合わせ(この記事では`ルール`と呼ぶことにする)をここで定義していく．デフォルトでいくつか定義されているがすべて無効化されている．  
    また`jail.d/*.conf`も読み込むようになっている．
* filter.d/*.conf  
    どのログをどんな正規表現で監視するか(filter)を定義する
* action.d/*.conf  
    IPをブロックする方法(action)を定義する

## 設定ファイルの書き方
デフォルトでは`.conf`ファイルが作成されているが，これらのファイルは編集せずに同名の`.local`ファイルを同じディレクトリに作る方法が推奨されている．
`.conf`のうち上書きしたい部分だけを`.local`ファイルに書けばその部分だけ上書きされる．

jailの設定は各ルール共通の設定を`jail.local`に書き，各ルールの設定と有効化を`jail.d/*.local`に書くことにするときれいに管理できそう．

# fail2banのしくみ

1. jailのlogpathに設定したログファイルをtail
1. jailのfilterに設定した条件(ログイン失敗など)に一致したログをカウント  
    このときログに含まれる「アクセス元IPアドレス」も認識しておく
1. 設定した頻度に逹したIPアドレスをブロック  
    ブロックの手段はjailのbanactionで設定する

# 設定
上に書いたやりたいことを実現すべく設定していく．

## SSHで認証に失敗したアクセスの送信元アドレスをBotとみなす
jail.confにははじめから以下の内容が書かれている(抜粋)

jail.conf:

``` ini
[DEFAULT]
enabled = false
filter = %(__name__)s

[sshd]
port    = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s
```

* `sshd`jailは定義されているが無効化されている
* filter名は`sshd`(fail名と同名)
* `sshd_log`の値は別ファイルで定義されている

パラメータはこのままでよさそうなのでこのjailを有効化する

jail.d/sshd.local:

``` ini
[sshd]
enabled = true
```

## HTTPやHTTPSでよくある攻撃対象のパスへアクセスしてきた送信元アドレスをBotとみなす
自分の環境ではNginxでこれらのポートをリッスンしている．これもやりたいことを実現できそうなjailがデフォルトで定義されている．

jail.conf:

``` ini
[nginx-botsearch]
port     = http,https
logpath  = %(nginx_error_log)s
maxretry = 2
```

error¥_logを見るようになっているが自分の場合はaccess¥_logを見てリクエストのパスから判断したかったのでいくつか設定を変更した．filterも上書きしている．

filter.d/nginx-botsearch.local:

``` ini
[Definition]
failregex = ^<HOST> \- \S+ \[\] \"(GET|POST|HEAD) \/<block> \S+\" .+$
            ^ \[error\] \d+#\d+: \*\d+ (\S+ )?\"\S+\" (failed|is not found) \(2\: No such file or directory\), client\: <HOST>\, server\: \S*\, request: \"(GET|POST|HEAD) \/<block> \S+\"\, .*?$
            ^<HOST> -.*"(GET|POST|PUT|HEAD) .*\.(php|jsp) HTTP\/.*$
            ^<HOST> -.*"GET https?\:\/\/.*/latest/meta-data HTTP\/.*$
ignoreregex =
```

jail.d/nginx-botsearch.local:

``` ini
[nginx-botsearch]
enabled  = true
logpath  = %(nginx_access_log)s
```

## BotとみなしたIPアドレスからのアクセスは以後すべてのポートでDROPするようにする
これはactionで設定する．
このサーバではFirewalldを使用しているので，fail2banでもFirwalldを通して設定するようにしたい．また今回の設定では大量のIPアドレスをブロックすることになるのでipsetを使いたい．(iptablesに大量のルールを設定するとパフォーマンスに影響がありそうだったため)
これを実現できそうなactionはデフォルトでは存在しなかったため，一番近そうな`firewallcmd-ipset`jailを改変することにした．
fail2ban起動時にipsetを作成しDROPするようなルールをFirewalldで設定している(ダイレクトルールを使用)．
検知時にipsetへIPアドレスを追加するようにする．

action.d/firewallcmd-ipset.local:

``` ini
[Definition]
actionstart = ipset create fail2ban-<name> hash:ip
              firewall-cmd --direct --add-rule ipv4 filter <chain> 0 -m set --match-set fail2ban-<name> src -j <blocktype>

actionstop = firewall-cmd --direct --remove-rule ipv4 filter <chain> 0 -m set --match-set fail2ban-<name> src -j <blocktype>
             ipset flush fail2ban-<name>
             ipset destroy fail2ban-<name>

actionban = ipset add fail2ban-<name> <ip> -exist

[Init]
blocktype = DROP
```

jail.local:

``` ini
(抜粋)
[DEFAULT]
banaction = firewallcmd-ipset
```

## 一度BotとみなしたIPアドレスは永久にブロックする

`jail.conf`(`jail.local`)には`bantime`というパラメータがある

```
bantime
    effective ban duration (in seconds).
```

永久にBANしたい場合の値が読みとれなかったが，試してみたところ0にするとBANした瞬間にunBANの処理が実行されてしまった．よってここの値は便宜上-1にしておく．

jail.local:

``` ini
(抜粋)
[DEFAULT]
bantime = -1
```

ここの値はactionの中で`<bantime>`のように書くことで使用できる．今回の場合はactionを自分で定義したが，上で書いた定義で永久BANが実現できている．
ipsetはtimeoutオプションでエントリの寿命を設定できるが，何も指定しないと永久にエントリが残るようだった．

以上．
