+++
date = "2017-06-15T23:14:55+09:00"
slug = ""
tags = ["ITインフラ", "読書"]
title = "Infrastructure as Code 感想 (3章)"
aliases = ["/blog/infrastructure-as-code-chap3/"]

+++

オライリーの「Infrastructure as Code」を読んで思ったことや自分的メモをまとめておく．**太字は自分の感想**， _斜字体は本からの引用_ ，そのほかは本の要約など．

## ツールの要件
* 他のツールを連携しやすいこと
    * コマンドライン引数や環境変数などでの入力，パースしやすい結果出力
    * 設定の外在化
* 自動実行しやすいこと
    * 冪等性など
    * 失敗したらわかる
* **周辺のツールとの連携しやすさは意識して考慮に入れてなかった**
* **考え方はすごくよくわかる．UNIX哲学に通じている**

## 構成レジストリ
* コンフィグ定義ツールが提供するもの(Chef Server, Ansible Towerなど)
* Zookeeper/Consul/etcd
* _プログラムによるレジストリエントリの追加，更新，削除をサポートしていること_
* **こういうのほしいと前から思っていたけどどうやって実装すればいいか，定義ツールとどう連携させればいいかイメージついてない**

### 軽い構成レジストリ
* S3やVCS上のファイル
    * HTTP等で配布．こうすることで可用性，スケーリングしやすい．管理が単純
    * 頻繁に更新されて複雑になる部分は分割やシャーディングで対応する
* **こうした場合，例えばAnsibleへはどうやって渡せばいいんだろうか**
    * **`ansible-playbook`実行前にyaml組んで`var_file`などに渡す**
        * **ダイナミックインベントリみたいなことはできなさそう．一回ファイルに吐き出す必要がある？**
    * **json組み立てて`ansible-playbook`の`--extra-vars`オプションに渡す**
    * **Ansible TowerのAPIでも渡せるかも**
* Consumer Driven Contract Testing
    * **Itamaeの`node.validate!`はまさにこれだと思う**[^1]
    * **こんな記事出てきた** [Consumer-Driven Contracts: A Service Evolution Pattern](https://martinfowler.com/articles/consumerDrivenContracts.html)
    * **[Pact](https://docs.pact.io/)のようなツールで容易に書けそう**

## CMDB
* CMDBとInfrastructure as Codeは構成管理に対するアプローチが正反対．両者を同一視してはならない
    * ただしすべてを自動化するならInfrastructure as CodeはCMDBを兼ねることができる．またはInfrastructure as CodeがCMDBも管理することができる
    * **ハードウェアも含めてすべてを自動化はけっこうハードル高そう**

## その他
* **インフラを完全に管理，自動化するために，やり方を変えるだけでなく自動化しやすいようにタスクそのものを見直すメンタルを忘れてはいけない**

以上

## 参考文献
1. Kief Morris, Infrastructure as Code クラウドにおけるサーバ管理の原則とプラクティス, 長尾高弘訳, オライリー・ジャパン, 2017

[^1]: [Best Practice · itamae-kitchen/itamae Wiki](https://github.com/itamae-kitchen/itamae/wiki/Best-Practice#use-nodevalidate-in-recipes-that-will-be-included)

{{< affiliate asin="4873117968" title="Infrastructure as Code ―クラウドにおけるサーバ管理の原則とプラクティス" >}}
