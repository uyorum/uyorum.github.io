+++
slug = ""
tags = []
title = "Raspberry Pi 4BにKubernetesをインストール（2021年版）"
date = "2021-04-04T22:18:27+09:00"
aliases = ["/blog/k8s-on-rpi4/"]

+++

Kubernetesの状況を加味した構成と手順。できるだけ一次情報も示しながら記録を残していく。

<!--more-->

## ハードウェア構成

* Raspberry Pi 4B（RAM4GB版）* 3
* 電源  
    [Omars USB充電器 ACアダプター（60W 6ポート）](https://amzn.to/2QzF5Ig)
* スイッチングハブ  
    [エレコム スイッチングハブ ギガビット 5ポート](https://amzn.to/3e9TYJm)
* スタッキングケース  
    [GeeekPi Raspberry Pi4クラスターケース](https://amzn.to/2QvC5fE)
* USB Type-Cケーブル  
    [USB Type C 充電ケーブル0.3m](https://amzn.to/3dmd2EQ)  
    L字でかさばらないし長さもちょうどよい
* LANケーブル  
    [エレコム LANケーブル 0.3m](https://amzn.to/32kOMwB)  
    CAT6である必要はないが柔らかくて扱いやすく、長さもちょうどよかった

## ソフトウェア構成

* Raspberry Pi OS 10
* Kubernetes 1.20
* コントロールプレーンノード 1台、ワーカーノード 2台構成
* コンテナランタイムにはCRI-Oを使う  
    Web上の記事ではDockerを使っているものが多いが、[k8s 1.20ではDockerのサポートが非推奨になった](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.20.md#deprecation)ためDockerの使用はやめる。
    [ドキュメント](https://kubernetes.io/ja/docs/setup/production-environment/container-runtimes/)ではCRI-OとContainerdが挙げられている。
    k8sを使う上でこれらに優位な差があるのかはわからないが、より軽量な実装らしいCRI-Oを選択した。
* ネットワークアドオンにはFlannelを使う  
    なぜか[v1.19のドキュメントには](https://v1-19.docs.kubernetes.io/ja/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#pod-network)よく使われるネットワークプラグインの一覧があるのでここを見て決めた。
    Calicoが機能的には柔軟そうだが、ここではよりシンプルそうなFlannelを選択した。

## 構築の流れ
kubeadmを使ってk8sをデプロイする。基本的には[ドキュメント](https://kubernetes.io/ja/docs/setup/production-environment/tools/kubeadm/)に従ってセットアップを進めればよい。
コントロールプレーンノード1台、ワーカーノード2台の構成で構築する。

### Raspberry Pi OSのセットアップ
SDカードへイメージを焼く方法は省略。
イメージを焼いたあとにいくつか初期設定を仕込んでおく。

* [SSHdを起動](https://www.raspberrypi.org/documentation/configuration/boot_folder.md)
* cgroupのメモリ機能を有効化
* [GPIO3ピンでシャットダウンをできるように（ついで）](https://github.com/raspberrypi/firmware/blob/master/boot/overlays/README#L1008)

自分の場合はWSL2で実行している。その他の環境で実行する場合は最初のマウント方法が異なる。

``` shell
$ mkdir mnt
$ sudo mount -t drvfs d: mnt
$ cd mnt
$ touch ssh
$ sudo sed -i 's/$/ cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1/g' cmdline.txt
$ echo 'dtoverlay=gpio-shutdown,gpio_pin=3' | sudo tee -a config.txt
$ cd -
$ sudo umount mnt
```

OS起動後、SSHでログインしいくつか追加の設定を行う。

* piユーザの`authorized_keys`にSSH公開鍵を追加
* `raspi-config`
    * Hostname
    * GPU Memoryを16MBに変更（画面は使わないので）
    * TimezoneをAsia/Tokyoに変更
* [ネットワーク設定（DHCPを使わない）](https://www.raspberrypi.org/documentation/configuration/tcpip/)
* SSHでパスワードログインを禁止
* [スワップをオフ](https://kubernetes.io/ja/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#%E5%A7%8B%E3%82%81%E3%82%8B%E5%89%8D%E3%81%AB)
* OSを最新化、再起動

以後、SSHで`pi`ユーザでログインし実行する。

``` shell
$ sudo raspi-config
cat <<EOF >>/etc/dhcpcd.conf

interface eth0
static ip_address=STATIC_ADDRESS/24
static routers=DEFAULT_GATEWAY
static domain_name_servers=NAME_SERVER
EOF
$ sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
$ sudo dphys-swapfile swapoff
$ sudo systemctl stop dphys-swapfile
$ sudo systemctl disable dphys-swapfile
$ sudo apt update
$ sudo apt upgrade -y
$ sudo reboot
```

DNSサーバに各ノードのホスト名を登録しておく。
ここまでを計3台で行っておく。

## Kubernetesセットアップ
[kubeadmを使ってクラスターを構築する | Kubernetes](https://kubernetes.io/ja/docs/setup/production-environment/tools/kubeadm/)
Kubernetesクラスタのセットアップにはkubeadmを使う。
全体的な流れとしては、以下のようになる。

1. （全ノード）事前準備
2. （全ノード）CRI-Oをインストール
3. （全ノード）kubeadm、kubelet、kubectlをインストール
4. （コントロールプレーンノード）kubeadmを使ってKubernetesクラスタをインストール
5. （コントロールプレーンノード）クラスタへFlannelをインストール
6. （ワーカーノード）クラスタへノードとして登録

### 事前準備
[kubeadmのインストール | Kubernetes](https://kubernetes.io/ja/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
ここに事前に設定すべき箇所が書かれている。

#### MACアドレスとproduct_uuidが全てのノードでユニークであることの検証
当然MACアドレスは全ノードで異なる。
またRaspberry Pi OSでは`/sys/class/dmi/id/product_uuid`は存在しなかった。ここは無視しても特に問題なくセットアップできた。

#### ネットワークアダプタの確認
無線LANと有線LANの両方を使っている場合は問題になるかもしれない。
今回は有線LANしか使わないため特に問題ない。

#### iptablesがブリッジを通過するトラフィックを処理できるようにする
起動時のカーネルモジュールのロードは[systemd-modules-load.service](https://manpages.debian.org/stretch/systemd/systemd-modules-load.service.8.en.html)が担っている。
`/etc/modules-load.d/*.conf`を作成してモジュール名を列挙すればよい。

``` shell
$ cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF
$ sudo modprobe br_netfilter

$ cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
$ sudo sysctl --system
```

#### iptablesがnftablesバックエンドを使用しないようにする
Raspberry Pi OS 10ではすでにnftablesへ移行しているためiptablesを使うように設定する必要がある。
手順はドキュメントに記載されている通り。

``` shell
$ sudo apt install -y iptables arptables ebtables
$ sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
$ sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
$ sudo update-alternatives --set arptables /usr/sbin/arptables-legacy
$ sudo update-alternatives --set ebtables /usr/sbin/ebtables-legacy
```

#### 必須ポートの確認
Raspberry Pi OSではデフォルトで全許可となっているためこのままでいくなら特に気にする必要はない。

``` shell
$ sudo iptables -S
-P INPUT ACCEPT
-P FORWARD ACCEPT
-P OUTPUT ACCEPT
```

### CRI-Oをインストール
[CRIのインストール | Kubernetes](https://kubernetes.io/ja/docs/setup/production-environment/container-runtimes/#cri-o)
[cri-o](https://cri-o.io/)

事前準備はKubernetesのドキュメント通りに行う

``` shell
$ cat <<EOF | sudo tee /etc/modules-load.d/crio.conf
overlay
br_netfilter
EOF
$ sudo modprobe overlay
$ sudo modprobe br_netfilter

$ cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
$ sudo sysctl --system
```

CRI-OのインストールにはOSとVersionを指定する必要がある。
VersionはKubernetesと合わせる必要があるので1.20を指定する。
aptのソースに追加するURL（[ここ](https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/)と[ここ](http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/1.20/)）を見てみると、
幸い`Raspbian_10`というディレクトリがあるのでOSではこれを指定する。

``` shell
$ OS=Raspbian_10
$ VERSION=1.20
$ cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /
EOF
$ cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list
deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /
EOF
$ curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg add -
$ curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg add -
$ sudo apt update
$ sudo apt install -y cri-o cri-o-runc
$ sudo systemctl daemon-reload
$ sudo systemctl enable crio
$ sudo systemctl start crio
```

### kubeadm、kubelet、kubectlをインストール
[kubeadmのインストール | Kubernetes](https://kubernetes.io/ja/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#kubeadm-kubelet-kubectl%E3%81%AE%E3%82%A4%E3%83%B3%E3%82%B9%E3%83%88%E3%83%BC%E3%83%AB)

``` shell
$ sudo apt-get update && sudo apt-get install -y apt-transport-https curl
$ curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
$ cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
$ sudo apt update
$ sudo apt install -y kubelet kubeadm kubectl
$ sudo apt-mark hold kubelet kubeadm kubectl
$ cat <<EOF | sudo tee /etc/default/kubelet
KUBELET_EXTRA_ARGS=--container-runtime-endpoint='unix:///var/run/crio/crio.sock'
EOF
```

#### コントロールプレーンノードのkubeletによって使用されるcgroupドライバーの設定
はじめは`/etc/default/kubelet`で`--cgroup-driver=systemd`を指定していたがkubelet起動時に以下の警告がログに出ていた。

```
Flag --cgroup-driver has been deprecated, This parameter should be set via the config file specified by the Kubelet's --config flag
```

`--config`フラグに渡しているファイルは`/var/lib/kubelet/config.yaml`

``` shell
$ sudo systemctl cat kubelet | grep -- --config
Environment="KUBELET_CONFIG_ARGS=--config=/var/lib/kubelet/config.yaml"
```

[cgroupDriver](https://github.com/kubernetes/kubernetes/blob/master/staging/src/k8s.io/kubelet/config/v1beta1/types.go#L428)というパラメータが使える模様。
このファイルに`cgroupDriver: systemd`という行を追加してkubeletを再起動。

``` shell
$ systemctl daemon-reload
$ systemctl restart kubelet
```

### kubeadmを使ってKubernetesクラスタをインストール
[kubeadmを使用したクラスターの作成 | Kubernetes](https://kubernetes.io/ja/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)

* 今回の構成ではコントロールプレーンノードは1台のみなので本来不要だが、将来的にコントロールプレーンノードを冗長化したくなった場合に備えて`--control-plane-endpoint`を指定する。
* ネットワークアドオンはFlannelを使うため、適切な`--pod-network-cidr`を指定する（参照：[flannel/kubernetes.md at master · flannel-io/flannel](https://github.com/flannel-io/flannel/blob/master/Documentation/kubernetes.md)）

``` shell
$ sudo kubeadm init --control-plane-endpoint=k8s-endpoint.test.local --pod-network-cidr=10.244.0.0/16
```

うまくいくと以下のようなメッセージが出力される。ここで出力されたコマンドをメモしておく。
`Then you can join any number of worker nodes by running the following on each as root:`

また、DNSサーバにAレコードやCNAMEレコードを追加して`k8s-endpoint.test.local`をコントロールプレーンノードへ向けておく。

#### kubectlの設定
コントロールプレーンノードで`kubectl`を使えるように設定ファイルをコピーする。

``` shell
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### クラスタへFlannelをインストール
[flannel-io/flannel: flannel is a network fabric for containers, designed for Kubernetes](https://github.com/flannel-io/flannel#deploying-flannel-manually)

マニフェストが配布されているのでこれを使う。一応masterブランチではなく最新タグのものを使う。

``` shell
$ kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.13.0/Documentation/kube-flannel.yml
```

### クラスタへノードとして登録
[kubeadmを使用したクラスターの作成 | Kubernetes](https://kubernetes.io/ja/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#join-nodes)

`kubeadm init`実行時に出力されたコマンドを各ワーカーノードで実行。

## 確認

``` shell
$ kubectl get node
NAME           STATUS   ROLES                  AGE   VERSION
k8s-master01   Ready    control-plane,master    1d   v1.20.2
k8s-node01     Ready    <none>                  1d   v1.20.2
k8s-node02     Ready    <none>                  1d   v1.20.2
```

Nginxコンテナをデプロイしてみる。
コントロールプレーンノードで以下を実行。

``` shell
$ cat <<'EOF' >nginx.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  labels:
    app.kubernetes.io/name: nginx
    app.kubernetes.io/component: app
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: nginx
      app.kubernetes.io/component: app
  replicas: 1
  template:
    metadata:
      labels:
        app.kubernetes.io/name: nginx
        app.kubernetes.io/component: app
    spec:
      containers:
      - name: nginx
        image: nginx
        resources:
          requests:
            cpu: 100m
            memory: 100Mi
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app.kubernetes.io/name: nginx
    app.kubernetes.io/component: app
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
    app.kubernetes.io/name: nginx
    app.kubernetes.io/component: app
EOF
$ kubectl create project sample-app
$ kubectl apply -f nginx.yaml --namespace sample-app
$ kubectl get pod --namespace=sample-app -o wide
NAME                     READY   STATUS    RESTARTS   AGE     IP           NODE         NOMINATED NODE   READINESS GATES
nginx-68d96c59fb-nstnz   1/1     Running   0          4m29s   10.244.1.5   k8s-node01   <none>           <none>
$ kubectl get svc --namespace=sample-app
NAME    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
nginx   ClusterIP   10.108.71.226   <none>        80/TCP    2m9s
$ curl 10.108.71.226
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

ひとまずクラスタ内からPodへアクセスすることはできた。

以上
