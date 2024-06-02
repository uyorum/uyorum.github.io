+++
slug = ""
tags = ["rhel", "openshift"]
title = "MicroShiftをインストールする"
date = "2024-04-20T18:01:51+09:00"
+++

PC環境の見直しによりN100ミニPCが余ったので自宅サーバーにするためにRHELとMicroShiftを入れてみた。

<!--more-->

## MicroShiftとは

[What is MicroShift?](https://www.redhat.com/ja/topics/edge-computing/microshift)

MicroShiftとは、エッジコンピューティング向けのOpenShiftビルドです。  
上記の記事によると、フットプリントの小ささが最大の特徴だそうです。OpenShiftもシングルノード構成をサポートしており、そこそこ小規模な環境にも導入できると思いますが、MicroShiftはそれよりもさらに小さいようです。
ドキュメントに記載されているシステム要件からもそれがわかります。

||CPU|メモリ|ディスク|
|:--|:--|:--|:--|
|[MicroShift](https://access.redhat.com/documentation/ja-jp/red_hat_build_of_microshift/4.15/html/installing/microshift-install-rpm#microshift-install-system-requirements_microshift-install-rpm)|2コア|2GB|10GB|
|[OpenShift（シングルノード構成）](https://access.redhat.com/documentation/ja-jp/openshift_container_platform/4.15/html/installing/installing-on-a-single-node#install-sno-requirements-for-installing-on-a-single-node_install-sno-preparing)|8コア|16GB|120GB|

上記の通り、4コア、メモリ16GBしかないN100ミニPCにはシングルノード構成の場合でも重荷です。

## ハードウェア

今回使っていくHWはこれ

{{< affiliate asin="B0C4SRHCTH" title="Beelink ミニPC 16GB DDR4 500GB SSD Intel N100" >}}

## 設計

ざっとこんな設計で進めていきます。

### OS

これを書いている時点で最新のRHEL9.3を入れることにします。

### サブスクリプション

[Devloper Subscription for Individual](https://developers.redhat.com/articles/faqs-no-cost-red-hat-enterprise-linux)を使用します。
このサブスクリプションにはOpenShiftも含まれています。

``` shell
$ sudo subscription-manager repos
...
Repo ID:   rhocp-4.15-for-rhel-9-x86_64-rpms
Repo Name: Red Hat OpenShift Container Platform 4.15 for RHEL 9 x86_64 (RPMs)
Repo URL:  https://cdn.redhat.com/content/dist/layered/rhel9/x86_64/rhocp/4.15/os
Enabled:   0
...
```

### MicroShift  

OSと同じく最新の4.15を入れます。

実はこれを書いている時点では4.16のリポジトリも存在はしているようですがアクセスすると403が返ってきてしまいます。  
RHOCP 4.16自体もまだリリース前のようなのでまだ使えないと判断し、今回は4.15を入れることにします。

``` shell
$ sudo yum check-update
Updating Subscription Management repositories.
Red Hat OpenShift Container Platform 4.16 for RHEL 9 x86_64 (RPMs)                                                                                                               623  B/s | 481  B     00:00
Errors during downloading metadata for repository 'rhocp-4.16-for-rhel-9-x86_64-rpms':
  - Status code: 403 for https://cdn.redhat.com/content/dist/layered/rhel9/x86_64/rhocp/4.16/os/repodata/repomd.xml (IP: 23.42.76.83)
Error: Failed to download metadata for repo 'rhocp-4.16-for-rhel-9-x86_64-rpms': Cannot download repomd.xml: Cannot download repodata/repomd.xml: All mirrors were tried
```

### LVM

MicroShiftはPVのバックエンドとして標準で[topolvm](https://github.com/topolvm/topolvm)がサポートされています。
topolvmについては開発者によるサイボウズのエンジニアブログがわかりやすいです。

[Kubernetesでローカルストレージを有効活用しよう - Cybozu Inside Out | サイボウズエンジニアのブログ](https://blog.cybozu.io/entry/2019/11/08/090000)

簡単に言うと、あらかじめLVM上でVG（Volume Group）を用意しておくことでMicroShiftがPVCに応じて自動でLV（Logical Volume）を作成してくれるようになります。
[LVMシンプール](https://access.redhat.com/documentation/ja-jp/red_hat_enterprise_linux/6/html/logical_volume_manager_administration/thinly_provisioned_volume_creation)にも対応しており、LVをシンプロビジョニングで作成することも可能です。

MicroShiftはデフォルトで「rhel」という名前のVGからLVを切り出そうとします。RHELインストール時に作成されるVGのデフォルト名ですね。
RHELインストール時に`/`等に割り当てる容量を少し小さくし、`rhel`VGの容量を余らせておきます。手順は[こちら](https://access.redhat.com/documentation/ja-jp/red_hat_build_of_microshift/4.15/html/installing/microshift-install-rpm-preparing_microshift-install-rpm)を参考に。

LVMシンプールを使用する場合はあらかじめ作成しておく必要があります。今回は容量を余らせた`rhel`VG上にシンプールを作成します。

## 手順
### MicroShiftインストール

[1.5. RPM パッケージからの Red Hat build of MicroShift のインストール Red Hat build of MicroShift 4.15 | Red Hat Customer Portal](https://access.redhat.com/documentation/ja-jp/red_hat_build_of_microshift/4.15/html/installing/installing-microshift-from-rpm-package_microshift-install-rpm)  
上記ドキュメントにそってインストールしていきます。

なおRHELはカスタマーポータルへの登録とサブスクリプションのアタッチが完了しているものとします。

``` shell
$ sudo subscription-manager repos --enable rhocp-4.15-for-rhel-9-$(uname -m)-rpms --enable fast-datapath-for-rhel-9-$(uname -m)-rpms 
$ sudo dnf install -y microshift
```

https://console.redhat.com/openshift/install/pull-secret
からプルシークレットをダウンロードし`/etc/crio/openshift-pull-secret`に配置しておきます。

``` shell
$ sudo chown root:root /etc/crio/openshift-pull-secret
$ sudo chmod 600 /etc/crio/openshift-pull-secret
$ sudo firewall-cmd --permanent --zone=trusted --add-source=10.42.0.0/16
$ sudo firewall-cmd --permanent --zone=trusted --add-source=169.254.169.1
$ sudo firewall-cmd --reload
```

すぐに必要ではありませんが手順にそってOperator Lifecycle Manager (OLM) とArgo CDもインストールしておきます。

``` shell
$ sudo dnf install -y microshift-olm
$ sudo subscription-manager repos --enable=gitops-1.12-for-rhel-9-$(uname -m)-rpms
$ sudo dnf install -y microshift-gitops
$ sudo systemctl restart microshift
```

MicroShiftを起動させます。

``` shell
$ sudo systemctl enable --now microshift
$ sudo systemctl is-active microshift
active
```

### `oc`コマンドの設定

``` shell
$ mkdir -p ~/.kube/
$ sudo cat /var/lib/microshift/resources/kubeadmin/kubeconfig > ~/.kube/config
$ oc get all -A
$ oc get pods -n openshift-gitops
NAME                                  READY   STATUS    RESTARTS   AGE
argocd-application-controller-0       1/1     Running   0          8m27s
argocd-redis-769db95b95-7w7qj         1/1     Running   0          8m27s
argocd-repo-server-7b54ffcc5f-c4ndm   1/1     Running   0          8m27s
```

ocコマンドで情報が取得できるようになりました。

### LVMシンプールの設定

[第7章 ボリュームスナップショットの使用 Red Hat build of MicroShift 4.15 | Red Hat Customer Portal](https://access.redhat.com/documentation/ja-jp/red_hat_build_of_microshift/4.15/html/storage/working-with-volume-snapshots-microshift#microshift-lvm-thin-volumes_volume-snapshots-microshift)

シンプールを作成し、それを使うようMicroShiftを設定します。
作成するシンプールのサイズは100GiBにし、10倍までオーバープロビジョニングを許可します。

``` shell
$ sudo lvcreate -L 100G -T rhel/ocpthinpool
  Thin pool volume with chunk size 64.00 KiB can address at most <15.88 TiB of data.
  Logical volume "ocpthinpool" created.
$ cat <<EOF | sudo tee /etc/microshift/lvmd.yaml
socket-name:
device-classes:
  - name: thin
    default: true
    spare-gb: 0
    thin-pool:
      name: ocpthinpool
      overprovision-ratio: 10
    type: thin
    volume-group: rhel
EOF
$ sudo systemctl restart microshift
```

ストレージクラスはデフォルトで作成されているので特に設定不要です。

``` shell
$ oc get storageclasses.storage.k8s.io topolvm-provisioner -o yaml
allowVolumeExpansion: true
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
  creationTimestamp: "2024-04-06T10:06:36Z"
  name: topolvm-provisioner
  resourceVersion: "391"
  uid: 29bf1ab6-82c2-4274-9aeb-ea099306cf51
parameters:
  csi.storage.k8s.io/fstype: xfs
provisioner: topolvm.io
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
```

### その他の設定

Ingress ControllerでServiceを公開する際のドメインだけ設定しておきます。
ゆくゆくは正式なワイルドカード証明書を取得できるよう、私が持っているドメインにしています。

``` shell
$ cat <<EOF | sudo tee /etc/microshift/config.yaml
dns:
    baseDomain: uyorum.net
EOF
$ sudo systemctl restart microshift
```

## コンテナをデプロイしてみる

試しにNginxのコンテナをデプロイしMicroShiftの外部へ公開してみます。

``` shell
$ oc create deployment hello --image=docker.io/nginx:stable-alpine
deployment.apps/hello created
$ oc expose deployment hello --port=80
service/hello exposed
$ oc expose svc hello
route/hello exposed
$ oc get deploy,pod,svc,route
NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/hello   1/1     1            1           2m6s

NAME                         READY   STATUS    RESTARTS   AGE
pod/hello-64bbcd7789-qdq24   1/1     Running   0          2m6s

NAME                 TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
service/hello        ClusterIP   10.43.32.194   <none>        80/TCP    96s
service/kubernetes   ClusterIP   10.43.0.1      <none>        443/TCP   7d3h

NAME                             HOST                             ADMITTED   SERVICE   TLS
route.route.openshift.io/hello   hello-default.apps.uyorum.net    True       hello
```

手元のPCで`https://hello-default.apps.uyorum.net`でアクセスし、Nginxのデフォルトページが表示されることを確認します。  
hosts等で`hello-default.apps.uyorum.net`がMicroShiftホストのIPアドレスへ名前解決できるようにしておく必要があります。IPアドレスでのアクセスでは正しく表示されません。  
自分の場合は[ワイルドカードDNSレコードをEdge Routerで設定](../edge-router-wildcard-dns/)し、宅内からはホスト名でアクセスできるようにしました。

以上です。

{{< affiliate asin="B09MQ54CLV" title="OpenShift徹底入門" >}}

## 参考資料

* [MicroShiftを使ってエッジデバイスでOpenShiftを実行しよう！ - 赤帽エンジニアブログ](https://rheb.hatenablog.com/entry/2022/06/24/162156)
* [Red Hat Developer Programに参加して最新技術を学習しよう - 赤帽エンジニアブログ](https://rheb.hatenablog.com/entry/developer-program)
* [Product Documentation for Red Hat build of MicroShift 4.15 | Red Hat Customer Portal](https://access.redhat.com/documentation/ja-jp/red_hat_build_of_microshift/4.15)
