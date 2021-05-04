+++
date = "2017-06-29T21:52:49+09:00"
slug = ""
tags = ["",""]
title = "Infrastructure as Code 感想 (6-9章)"
aliases = ["/blog/infrastructure-as-code-chap6-9/"]

+++

オライリーの「Infrastructure as Code」を読んで思ったことや自分的メモをまとめておく．**太字は自分の感想**， _斜字体は本からの引用_ ，そのほかは本の要約など．

6~9章は各領域での設計パターンやプラクティスを整理している

## サーバーのプロビジョニング
* サーバーに含まれるもの
    * ソフトウェア
    * 構成/設定
    * データ
        * ログもここに含まれる
* **インフラストラクチャはサーバのアップデート，交換，削除のプロセスを通して，一貫して「データ」へのアクセス性を提供しなければならない**
* _プロセスのさまざまな部分にかかる時間を計測するようにしなければならない_
    * **これはいろんなところに言えそう．次からは時間を計測することを考えるようにしようと思う**

## サーバーのテンプレート管理
* 構築方法
    * 原始イメージでサーバーを作成し設定を変更する
    * ほかのサーバーに原始イメージディスクをマウントし変更を加える
        * chrootを使う
        * ブート，シャットダウンの時間を省略できる
        * テンプレート上にログが作成されないのでわざわざ削除する必要がない
        * [Netflix/aminator: A tool for creating EBS AMIs. This tool currently works for CentOS/RedHat Linux images and is intended to run on an EC2 instance.](https://github.com/Netflix/aminator)
        * **このやり方は思い付かなかった**
* テンプレート自体にもバージョン番号を付け，各サーバーがどのテンプレートから作成されたか追跡できるようにする
* テンプレートをアップデートしたら既存のサーバーも作成しなおせ，さもないと構成ドリフトが発生する
    * **これをやるのはすごく難しいと思うのだが．サービスを停止せずにサーバーを入れ替えなければならない**
    * **テンプレートに変更を加えたら既存サーバーにも同じ変更を加えるようにするのが妥協ラインかな…**

## サーバーのアップデート/変更
* プッシュ同期
* プル同期
    * **変更後のテストもサーバーから自発的に実行できる必要がある？**
      * サーバー上で動かしても問題なさそう：[aelsabbahy/goss: Quick and Easy server testing/validation](https://github.com/aelsabbahy/goss)
      * あるいはモニタリングにまかせる
    * **異常が起こった場合の切り戻しはどうやってトリガーする？**
* マスターレス構成管理
    * SPoFがなくなる
* **サーバー作成直後の設定とサーバーのアップデートは必ずしも同一の仕組みとは限らない，という前提でこの本は書かれている気がする**

## インフラストラクチャ定義
* 適切なスタックにインフラを分割し，定義，実装する
* _人々が変更を加えるのを恐れるようになったら，インフラストラクチャ定義がモノリシックになってきていると考えることができる_
* スタックの共有(DBサーバの共有など)は避けるべき
    * 5章で説明された通りどうしても共有されるサービスは存在する．その場合はサービスレベルを定める
* アプリケーションコードとインフラストラクチャコードを統一的に管理する
    * **Googleのような巨大リポジトリでの開発には，呼び出し先の変更と同時に呼び出し元も変更できるという利点がある．**[^1] **これと似たような考え方か．**
* 既存の設計パターンを当てはめようとすると，かえって複雑になる場合がある．設計を見直すことも必要
    * **管理しやすようにやり方を変える．手段と目的が逆転してるように感じるが大事**

## 参考文献
1. Kief Morris, Infrastructure as Code クラウドにおけるサーバ管理の原則とプラクティス, 長尾高弘訳, オライリー・ジャパン, 2017

[^1]: [Google の巨大レポジトリとブランチ無し運用 - Kato Kazuyoshi](http://2013.8-p.info/japanese/07-30-google-mainline.html)