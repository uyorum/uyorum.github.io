+++
date = "2017-06-21T22:47:39+09:00"
slug = ""
tags = ["ITインフラ", "読書"]
title = "Infrastructure as Code 感想 (5章)"
aliases = ["/blog/infrastructure-as-code-chap5/"]

+++

オライリーの「Infrastructure as Code」を読んで思ったことや自分的メモをまとめておく．**太字は自分の感想**， _斜字体は本からの引用_ ，そのほかは本の要約など．

### インフラストラクチャサービス，ツールが満たすべき条件

* 外部定義を使えるツールを選ぶ
    * **DBに設定を保持するツールはどうすればいいか**
        * **設定をyamlなどで構造化してテキストに保存．それを読み込んでAPIを発行，サービスへ設定を反映させる．確実に両者が同一の内容であることを確信するいは逆(サービスからyamlへ)もできる必要がある**
        * **インポート/エクスポートを使う．(エクスポートした設定情報は大抵は人間が読むようにはできていない．独自のフォーマットで書かれていて容易にパースできない)**
        * (本に書いてある例)SeleniumのようなものでGUIを操作する
    * **いずれにしても辛そう．よほどのことがない限りそのようなツールは選択すべきでない**
* インフラストラクチャがダイナミックだという前提で作られたツールを選ぶ
    * サービス自身とサービスが管理するものの変化に柔軟に**自動的に**追従，対処できるもの
* ライセンスがクラウド互換になっている製品を選ぶ
    * **ここでは主に柔軟性に関するもの**
* 疎結合をサポートする製品を選ぶ

## チーム間でのサービスの共有

* チーム間で共有される可能性のあるサービス
    * モニタリング，CI，バグ追跡(BTS？)，DNS，アーティファクトリポジトリ(構成レジストリ？)
* **それを使うチームの要件，使われ方の特性などが様々になり，それ自体が小さなパブリックサービスのようにみなせるかもしれない**
    * **それぞれサービスレベルやサービス仕様を定めてチームに使ってもらう**
    * **ふつうにマイクロサービスアーキテクチャの考え方みたい**

## モニタリング

* _モニタリングの目標は，必要とする人に必要なときに適切な情報を提供すること_
    * **つまり，モニタリングシステムの設計を始める前に想定ユーザを決めるフェーズがあるということ．今までは考えたことなかった**
* 個々のイベントは問題ないが，それが頻発する場合は問題がある可能性がある場合，頻度に関する閾値を設ける
* _(a)日常の仕事を続行する，(b)大声を出して今していることを中断し，対策に乗り出す どちらを取るべきかをすぐに判断できるようなのでなければならない_
* _複数のサーバーに関連性があることを自動的にタギングしなければならない_
    * **Zabbixでもネットワークディスカバリ，ローレベルディスカバリ，AgentのUserParameterあたりを使えば自動でタギングできるが，ダッシュボードを動的に生成できないのが辛い**
        * **つまりZabbixはInfrastructure as Codeに適していない**
    * **DataDogやMackerel(おそらくNewRelicも)はこのへんの考え方が前提になってる**
    * **Prometheusはこのあたりどうなんだろう．Grafanaと組み合わせれば普通にできそう(それを言えばZabbixでもいいのだが)**

## サービスディスカバリ

* サーバーサイドサービスディスカバリ
    * ロードバランサが結局ボトルネックになったりする
* クライアントサイドサービスディスカバリ
    * 通常，こちらの方がアプリケーションは複雑になる
    * **アプリケーションのlocalhostにロードバランサを用意すればいろいろ解決しそう**

## 参考文献

1. Kief Morris, Infrastructure as Code クラウドにおけるサーバ管理の原則とプラクティス, 長尾高弘訳, オライリー・ジャパン, 2017

{{< affiliate asin="4873117968" title="Infrastructure as Code ―クラウドにおけるサーバ管理の原則とプラクティス" >}}
