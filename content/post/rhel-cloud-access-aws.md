+++
slug = ""
tags = ["rhel"]
title = "RHELのサブスクリプションをCloud AccessでAWSに持ち込む"
date = "2023-01-05T20:07:45+09:00"
+++

[Red Hat Developer Subscription for Individuals](https://rheb.hatenablog.com/entry/developer-program)を使ってAWSにインスタンスを立ててみたのでメモ。

<!--more-->

Cloud Accessについては[赤帽エンジニアブログ](https://rheb.hatenablog.com/entry/ccsp-rhel)を読むのがいいと思います。ここでは省略。  
Red Hatはこういうものもドキュメントがしっかりあるので一通り読んでおきます。

[Red Hat Cloud Access リファレンスガイド Red Hat Subscription Management 2022 | Red Hat Customer Portal](https://access.redhat.com/documentation/ja-jp/red_hat_subscription_management/2022/html/red_hat_cloud_access_reference_guide/index)

## Cloud Accessのオプション

上記のドキュメントによるとCloud Accessには3つの方法があるらしい。

[第2章 Cloud Access の使用 Red Hat Subscription Management 2022 | Red Hat Customer Portal](https://access.redhat.com/documentation/ja-jp/red_hat_subscription_management/2022/html/red_hat_cloud_access_reference_guide/getting-started-with-ca_cloud-access)

読んだ感じ大体以下のような使い分けになるのかなと思います。

* 負荷なし  
    Red Hatによるゴールデンイメージを使わない場合にこのオプションを選択できる。  
    インスタンスがRed Hatのカスタマーポータルに紐付けずに使用するのがこのオプション。  
    サブスクリプションが足りているかどうかは自分で管理することになる。
* サブスクリプションの追跡およびゴールドイメージアクセス  
    カスタマーポータルを使う方法。システムとサブスクリプションをカスタマーポータル上で紐づけて管理、運用する。  
    このオプションではゴールデンイメージを使うことができる。  
    おそらくこれが一番オーソドックスな方法。
* 高度なRHEL管理  
    ハイブリッドクラウドコンソールを使ってより高度に管理する方法。  
    シンプルコンテンツアクセスを有効にする必要がある。（シンプルコンテンツアクセスについては後述）

せっかくなので自分は3番目の「高度なRHEL管理」を選択しました。

### シンプルコンテンツアクセス

[Simple Content Access - Red Hat Customer Portal](https://access.redhat.com/ja/articles/6098461)

従来のサブスクリプションの管理をより高度化したもののようです。  
具体的にはシステムにサブスクリプションを紐づける（attach）必要がなくなるようです。  
おそらくクラウド環境でサーバが頻繁に増減する状況のための仕組みなんだと思います。（想像）

高度なRHEL管理のためにはシンプルコンテンツアクセスを有効にする必要があるので始めに済ませておきます。  
方法は[上の記事](https://access.redhat.com/ja/articles/6098461#simple-content-access--red-hat-subscription-management--2)で説明されています。
手順はここでは省略。

## Cloud Accessを有効化

[2.3. オプション 3: 高度な RHEL 管理 Red Hat Subscription Management 2022 | Red Hat Customer Portal](https://access.redhat.com/documentation/ja-jp/red_hat_subscription_management/2022/html/red_hat_cloud_access_reference_guide/proc_new-ca-experience-option3_cloud-access)

ドキュメントの通りに進めていきます。

1. [ハイブリッドクラウドコンソール](https://console.redhat.com/)にログインします。IDとパスワードはカスタマーポータルと共通です
1. 画面上部のAll apps and servicesから「Sources」を検索します
1. [Add source]をクリックします
1. AWSを選択して次へ進みます
1. 管理上の名前を入力して次へ進みます
1. AWSアカウントとの紐づけのための設定をAWSに対して行います。方法は2つあります
    * 自動で行う場合…AWSのアクセスキーとシークレットアクセスキーを入力し自動で設定を行います
    * 手動で行う場合…指示された通りにAWSに自分で設定を行います

    前者がrecommentedだったため自分は前者を選択しましたがセキュリティが心配な場合は手動で行ったほうがよいでしょう。  
    アクセスキーの生成は[AWSのドキュメント](https://docs.aws.amazon.com/ja_jp/powershell/latest/userguide/pstools-appendix-sign-up.html)を参照。
1. 次へ進むと設定が開始されるので完了までしばらく待ちます

項目が3つありますがインスタンスの作成には「RHEL management」だけあればよいので他は無効化しておきます。
(上2つは数分で終わりましたがProvisioningだけは数日経っても終わりませんでした)

![cloudaccess-1](/rhel-cloud-access-aws/cloudaccess-1.jpg)

## ゴールデンイメージ

[3.5. AWS でのゴールドイメージの使用 Red Hat Subscription Management 2022 | Red Hat Customer Portal](https://access.redhat.com/documentation/ja-jp/red_hat_subscription_management/2022/html/red_hat_cloud_access_reference_guide/using-gold-images-on-aws_cloud-access)

RHEL managementの設定が完了後、しばらくするとAWSのマネジメントコンソールでゴールデンイメージがAMIとして見えるようになります。
自分の場合はAMIが見えるまで2～3日かかりました。

AMIはプライベートイメージとして見えてきます。「所有者=309956199498」で検索できます。

![cloudaccess-2](/rhel-cloud-access-aws/cloudaccess-2.jpg)

### Yumの向き先について

[3.3. 更新およびパッチ Red Hat Subscription Management 2022 | Red Hat Customer Portal](https://access.redhat.com/documentation/ja-jp/red_hat_subscription_management/2022/html/red_hat_cloud_access_reference_guide/con_updates-and-patches_cloud-access#doc-wrapper)

AWSのゴールデンイメージはデフォルトでRHUIを参照するように設定されています。  
このまま使い続けてもいいですしRHUIへの参照はやめて`subscription-manager`を使ってRed HatのCDNを参照してもよいです。  
ハイブリッドクラウドコンソールでAWSアカウントと紐づけたためか、カスタマーポータルには自動で登録されているので`subscription-manager repos --enable`で目的のリポジトリを有効にすればよいです。  
シンプルコンテンツアクセスでも説明した通り、サブスクリプションをアタッチする必要はありません。

``` shell
// RHUIは使わない
$ sudo sed -i 's/^enabled=1/enabled=0/g' /etc/yum.repos.d/redhat-rhui*.repo
// 起動時に戻ってしまうので止める
$ sudo systemctl disable choose_repo
// デフォルトでは`subscription-manager`による管理は無効化されているので有効化する
$ sudo subscription-manager config | grep -i manage_repo
   manage_repos = 0
$ sudo subscription-manager config --rhsm.manage_repos=1
$ sudo subscription-manager config | grep -i manage_repo
   manage_repos = [1]
// リポジトリを有効化 (RHEL9の場合)
$ sudo subscription-manager repos --enable rhel-9-for-x86_64-baseos-rpms
$ sudo subscription-manager repos --enable rhel-9-for-x86_64-appstream-rpms
$ sudo yum repolist
Updating Subscription Management repositories.
repo id                                                                         repo name
rhel-9-for-x86_64-appstream-rpms                                                Red Hat Enterprise Linux 9 for x86_64 - AppStream (RPMs)
rhel-9-for-x86_64-baseos-rpms                                                   Red Hat Enterprise Linux 9 for x86_64 - BaseOS (RPMs)
```

以上

## 参考

* [Red Hat Cloud Access リファレンスガイド Red Hat Subscription Management 2022 | Red Hat Customer Portal](https://access.redhat.com/documentation/ja-jp/red_hat_subscription_management/2022/html/red_hat_cloud_access_reference_guide/index)
* [AWS, AzureでRHELを利用する前に確認すること - 赤帽エンジニアブログ](https://rheb.hatenablog.com/entry/ccsp-rhel)
* [RHELのGold ImageをAWSに表示させる方法 - holyblueのブログ](https://blog.holyblue.jp/entry/2021/11/22/150759)

{{< affiliate asin="B0BF4DVCN3" title="バージョン8&9両対応! Red Hat Enterprise Linux完全ガイド " >}}
