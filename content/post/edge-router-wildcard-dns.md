+++
slug = ""
tags = ["edge-router"]
title = "Edge Router ER-XでワイルドカードDNSレコードを実装する"
date = "2024-04-15T00:05:01+09:00"
+++

<!--more-->

ER-XでワイルドカードDNSレコードを実装したかったので調査した。

## ワイルドカードDNSレコードとは

あまり聞かない設定だし規格化された正式な名称かどうかもわからないのでやりたかったことをここで定義しておく。

* あるドメインのすべてのサブドメインを特定のIPアドレスへ解決するようなAレコード

あるドメイン`example.com`があったとして、そのすべてのサブドメイン、例えば`foo.example.com`や`bar.example.com`のAレコードを引いた結果が特定のIPアドレス（例えば`192.0.2.1`）になるようにしたい。

コマンドで表現するとこんな感じ。

``` shell
$ dig +short foo.example.com
192.0.2.1
$ dig +short bar.example.com
192.0.2.1
```

もちろんどんなサブドメインの名前解決が発生するかは事前には分からないのであらかじめすべてのレコードを登録しておくなんてこともできない。

## 設定方法

Edge RouterのDNSサーバー機能は[dnsmasqで実装されている](https://help.ui.com/hc/en-us/articles/115010913367-EdgeRouter-DNS-Forwarding-Setup-and-Options)ためdnsmasqの機能を利用することになる。

GUIで設定する場合は`Config Tree`→`service`→`dns`→`forwarding`と辿ったところの`options`になる。
説明を読む感じdnsmasqのコンフィグを入力できる模様。
[dnsmasqのドキュメント](https://thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html)にはワイルドカードレコードのことはあまり書かれていないがStack Overflowによると以下のように書けばいいらしい。

> `address=/.example.com/192.0.2.1`

先頭の`.`はあってもなくても動作は変わらないらしいがサブドメインの名前解決を設定したいという意図を残すためあえて付けておく。

![edge-router-wildcard-dns](/edge-router-wildcard-dns/config.jpg)

ちなみにCLIで設定する場合は以下のコマンドになる。

``` shell
configure
set service dns forwarding options address=/.example.com/192.0.2.1
commit
```

以上。

{{< affiliate asin="B00YFJT29C" title="Ubiquiti EdgeRouter X Advanced Gigabit Ethernet Routers ER-X 256MB Storage 5 Gigabit RJ45 ports by Ubiquiti" >}}
