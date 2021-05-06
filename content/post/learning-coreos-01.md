+++
Categories = []
Tags = ["CoreOS", "Docker"]
title = "CoreOS入門1 etcd"
date = "2015-09-04T23:01:54+09:00"
aliases = ["/blog/learning-coreos-01/"]

+++

最近CoreOSを触りはじめたので学んだことをまとめていく．まずはetcdから．
最終的にはKubernetesでCoreOSをコントロールするところまでいきたいなーと思ってるが，いつになることやら．

<!--more-->

## 参考

* [coreos/etcd](https://github.com/coreos/etcd)
* [Getting Started with etcd on CoreOS](https://coreos.com/etcd/docs/latest/getting-started-with-etcd.html)
* [Clustering Machines](https://coreos.com/os/docs/latest/cluster-discovery.html)

## etcdとは

分散KVS．詳細はいろいろな方が紹介記事を書いているので省略．

以下，etcdによるクラスタの構成方法．  
etcdはv0.4系とv2.0系があり，それぞれコマンドオプションがほとんど違うので注意が必要．  
以下はetcd v2での説明．

## etcdクラスタを構成するには

マルチキャストを使って互いのノード(peerと呼ぶ)を自動で見つけてくれるたぐいのものではない．マルチクラウドやL3ネットワーク越しに使うことも想定しているからっぽい．  
よってノードは他のノードがどこにいるか(IPアドレス)を何らかの方法で取得しなければならない．以下の3つの方法がある．

* Static  
  クラスタのメンバのアドレスとポートが既にわかっている場合に使う．etcd起動時に他のノードのアドレスを与える．
* etcd discovery  
  各ノードのアドレスが事前にわからない場合に使う．詳しくは後述する
* DNS discovery  
  同上．DNSのSRVレコードを使う．よく調べてない．

### Discovery Serviceとは

etcdクラスタを初めに構築するときに利用するService．各ノードのetcdはこのServiceに自分のアドレスを登録し，同様に登録された他のノードのアドレスを知る．  
Discovery Serviceはクラスタの構築時にのみ使用される．既に稼動しているクラスタへのノードの追加やクラスタのモニタリングには利用しない．  
後からノードを追加したり除去するするときは[runtime](https://github.com/coreos/etcd/blob/master/Documentation/runtime-configuration.md)が使われる．  
Discovery ServiceのURLは通常使い回しはせずに構築するクラスタごとに生成しなおす．

### Public Discovery Serviceによるクラスタの構成

自分でDiscovery Serviceを立てる方法と専用のPublicサービスを利用する方法がある．  
前者は普通にetcdを起動すればいいみたい．ここでetcdを起動するホストはクラスタに参加させたいホストとは別物なので注意．これに気づくまでに時間がかかった．  
(Public Serviceの方法はetcd2でしか使えない？etcd 4.9ではなぜかだめだった．)  
Public Discovery Serviceを使うには

```shell
curl https://discovery.etcd.io/new?size=3
```

で返ってきたURLを`-discovery`オプションに指定してetcdを起動する．sizeにははじめにクラスタを構成する際のノード数を指定する．  
ここで指定する値は重要で，ここで指定した台数が集まらないとetcdクラスタが完成しない．(KVSが機能しない)

今回は1つのOSでポートを変えてetcdプロセスを3つ起動してクラスタを構成してみる．

* 環境

```shell
$ cat /etc/redhat-release 
CentOS Linux release 7.1.1503 (Core)
 
$ etcd --version
etcd Version: 2.0.13
Git SHA: 92e3895
Go Version: go1.4.2
Go OS/Arch: linux/amd64
```

ここではあえてCoreOSは使わない．etcdはCoreOSだけのものではないので．

このホスト上でetcdを3つ起動する．

name|client port|peer port
:--|:--|:--
machine1|2379|2380
machine2|22379|22380
machine2|32379|32380

* client port  
KVSへのアクセスを受け付けるポート
* peer port  
etcd同士で通信するときに使用するポート

1ノード目を起動させる

```shell
$ etcd -name machine1 -initial-advertise-peer-urls http://127.0.0.1:2380 \
> -listen-peer-urls http://127.0.0.1:2380 \
> -listen-client-urls http://127.0.0.1:2379 \
> -advertise-client-urls http://127.0.0.1:2379 \
> -discovery https://discovery.etcd.io/<token>
2015/08/31 22:03:06 etcd: no data-dir provided, using default data-dir ./machine1.etcd
2015/08/31 22:03:06 etcd: listening for peers on http://127.0.0.1:2380
2015/08/31 22:03:06 etcd: listening for client requests on http://127.0.0.1:2379
2015/08/31 22:03:06 etcdserver: datadir is valid for the 2.0.1 format
2015/08/31 22:03:07 discovery: found self b4adc113c23753cc in the cluster
2015/08/31 22:03:07 discovery: found 1 peer(s), waiting for 2 more
```

initial~で始まるオプションはクラスタの他のノードに伝えるURL(Discovery Serviceに登録される)  
listen~はそのまま．listenするポートとインターフェース  
**マルチクラウドなど，NAT環境なんかでは両者をしっかり区別する必要がある**  

残りのノードも同じように起動するとクラスタの構成が完了する

```shell
2015/08/31 22:07:45 raft: a956683cc771ba75 [logterm: 1, index: 3, vote: 0] voted for 2307dad4ec70be21 [logterm: 1, index: 3] at term 2
2015/08/31 22:07:45 raft.node: a956683cc771ba75 elected leader 2307dad4ec70be21 at term 2
2015/08/31 22:07:45 rafthttp: starting client stream to 2307dad4ec70be21 at term 2
2015/08/31 22:07:45 etcdserver: published {Name:machine1 ClientURLs:[http://127.0.0.1:32379]} to cluster 31fef011866a5fd7
```

このノードがクラスタのLeaderに選ばれたのがわかる．このへんはRaftというアルゴリズムが用いられているらしい．Raftについてはあとで調べたい．  
ちなみにクラスタ構成後にDiscovery URLを見てみると

```shell
$ curl https://discovery.etcd.io/9dfd14389c921bdde47847f13b7f51cb
{
  "node": {
    "createdIndex": 780131509.0,
    "modifiedIndex": 780131509.0,
    "nodes": [
      {
        "createdIndex": 780132766.0,
        "modifiedIndex": 780132766.0,
        "value": "machine1=http:\/\/127.0.0.1:2380",
        "key": "\/_etcd\/registry\/9dfd14389c921bdde47847f13b7f51cb\/a956683cc771ba75"
      },
      {
        "createdIndex": 780132931.0,
        "modifiedIndex": 780132931.0,
        "value": "machine2=http:\/\/127.0.0.1:22380",
        "key": "\/_etcd\/registry\/9dfd14389c921bdde47847f13b7f51cb\/2307dad4ec70be21"
      },
      {
        "createdIndex": 780133027.0,
        "modifiedIndex": 780133027.0,
        "value": "machine3=http:\/\/127.0.0.1:32380",
        "key": "\/_etcd\/registry\/9dfd14389c921bdde47847f13b7f51cb\/6693db807ca7130f"
      }
    ],
    "dir": true,
    "key": "\/_etcd\/registry\/9dfd14389c921bdde47847f13b7f51cb"
  },
  "action": "get"
}
```

jsonは別途，見やすくパースしてる．実際にはjsonが1行で表示される．

このクラスタに後からノードを追加したい場合は同じURLを指定してetcdを実行すればよい．内容を見て自動でクラスタに参加してくれる．
(このURLはいつまで有効？)

### KVSの使用

試しにKVSに値を入れてみる(APIは[ここ](https://github.com/coreos/etcd/blob/master/Documentation/api.md)を参照)

```shell
$ curl http://127.0.0.1:2379/v2/keys/foo -XPUT -d value=bar
{
  "node": {
    "createdIndex": 7,
    "modifiedIndex": 7,
    "value": "bar",
    "key": "\/foo"
  },
  "action": "set"
}
$ curl http://127.0.0.1:2379/v2/keys/foo
{
  "node": {
    "createdIndex": 7,
    "modifiedIndex": 7,
    "value": "bar",
    "key": "\/foo"
  },
  "action": "get"
}
```

登録された．別のノード(22379番ポート)に同じキーを問い合わせてみる

```shell
$ curl http://127.0.0.1:22379/v2/keys/foo
{
  "node": {
    "createdIndex": 7,
    "modifiedIndex": 7,
    "value": "bar",
    "key": "\/foo"
  },
  "action": "get"
}
```

## CoreOSでは

etcd2はsystemdによりdaemonとして起動させる．先ほどコマンドオプションで与えていた情報はCloud-Configで設定できる．

* cloud-config.yml

```yaml
coreos:
  units:
    - name: etcd2.service
      command: start
  etcd2:
    discovery: https://discovery.etcd.io/<token>
    listen-client-urls: http://0.0.0.0:2379
    advertise-client-urls: http://$private_ipv4:2379
    listen-peer-urls: http://$private_ipv4:2380
    initial-advertise-peer-urls: http://$private_ipv4:2380
```

tokenはもう一度取得しなおすこと．起動させてからコマンドで確認してみると．

```shell
$ fleetctl list-machines -l
MACHINE                                 IP              METADATA
4c5b32d1d79c47ff8e4847e1df78ab53        10.0.0.111      -
79e7347d66de4ce8b3ec423cdd93e314        10.0.0.124      -
ef6ce0b8871844beb929411f8926b686        10.0.0.139      -
```

クラスタを構成できていることがわかる．  
なお，Amazon EC2, Google Compute Engine, OpenStack, Rackspace, DigitalOcean, Vagrantに限り，`$private_ipv4`や`$public_ipv4`という変数が使える．

### 任意の環境でprivate_ipv4を使う

ここからは自分で検証した結果をまとめておく．

前述の通りprivate_ipv4等の変数は一部の環境でしか使えない．  
そのためCoreOSホスト毎にcloud-config.ymlを用意するでもない限り，その他の環境では少し工夫する必要がある．

`cloud-config.yml`を読み込むとetcdの設定ファイル`/run/systemd/system/etcd2.service.d/20-cloudinit.conf`が生成される．

```shell
[Service]
Environment="ETCD_ADVERTISE_CLIENT_URLS=http://:2379"
Environment="ETCD_DISCOVERY=https://discovery.etcd.io/7d7a0ede23474b12c32b88e5b968b2a5"
Environment="ETCD_INITIAL_ADVERTISE_PEER_URLS=http://:2380"
Environment="ETCD_LISTEN_CLIENT_URLS=http://0.0.0.0:2379"
Environment="ETCD_LISTEN_PEER_URLS=http://:2380"
Environment="ETCD_NAME=default"
```

`$private_ipv4`が空なのでIPアドレスが空になってる．  
1つの方法としてはOS起動後にこのファイルを編集してetcdを再起動することで対応できる．

または`/etc/environment`でも設定できる．このファイルを作成し，以下のような内容にすることでそれぞれ`$public_ipv4`と`$private_ipv4`がセットされる．

* /etc/environment

```shell
COREOS_PUBLIC_IPV4=XXX.XXX.XXX.XXX
COREOS_PRIVATE_IPV4=10.0.0.100
```

systemctlのunitを作成し，IPアドレスを取得し上記のファイルを作成するようにしている．

* cloud-config.yml

```yaml
coreos:
  update:
    reboot-strategy: reboot
    group: master
  units:
    # Create etcd2 parameters
    - name: create-etcd-env.service
      command: start
      content: |
        [Unit]
        Description=creates etcd environment
        Before=etcd2.service
 
        [Service]
        Type=oneshot
        ExecStart=/bin/bash -c "echo COREOS_PUBLIC_IPV4=`curl -s ipinfo.io | jq -r '.ip'` > /etc/environment"
        ExecStart=/bin/bash -c "echo COREOS_PRIVATE_IPV4=`ip addr show eth0 | grep -o 'inet [0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\.[0-9]\\+' | grep -o [0-9].*` >> /etc/environment"
        Execstart=/bin/systemctl restart user-configdrive.service
```

※ 最後に`user-configdrive.service`を再起動し設定ファイルを生成し直すようにしたいがなぜかうまくいかない．手で叩くとうまくいくのだが？？
