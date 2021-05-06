+++
Categories = []
Tags = ["Windows", "Hyper-V"]
title = "Hyper-V上の仮想マシンのIPアドレスをホスト側で取得する"
date = "2015-11-09T23:28:41+09:00"
aliases = ["/blog/get-ip-in-hyperv/"]

+++

「内部ネットワーク」を使用している場合，Hyper-VのGuestOSはDHCPでIPアドレスが振られる．
HostからGuestへアクセスするときにアドレスが変わると困る．
Guestを固定アドレスにすればいいのかも知れないが，何かの拍子でセグメントが変わったら面倒なので自動で取得できるようする．

<!--more-->

## 環境

### Host

```shell
> systeminfo
(抜粋)
OS Name:                   Microsoft Windows 10 Pro
OS Version:                10.0.10240 N/A Build 10240
```

### Guest

```shell
$ lsb_release -a
No LSB modules are available.
Distributor ID: Debian
Description:    Debian GNU/Linux unstable (sid)
Release:        unstable
Codename:       sid
```

## 準備

Guest OSにAgentをインストール

```shell
$ sudo apt-get install hyperv-daemons
$ dpkg -l hyperv-daemons
要望=(U)不明/(I)インストール/(R)削除/(P)完全削除/(H)保持
| 状態=(N)無/(I)インストール済/(C)設定/(U)展開/(F)設定失敗/(H)半インストール/(W)トリガ待ち/(T)トリガ保留
|/ エラー?=(空欄)無/(R)要再インストール (状態,エラーの大文字=異常)
||/ 名前                          バージョン          アーキテクチャ      説明
+++-=============================-===================-===================-================================================================
ii  hyperv-daemons                4.2-2               amd64               Support daemons for Linux running on Hyper-V
$ systemctl status hyperv-daemons.hv-fcopy-daemon.service
● hyperv-daemons.hv-fcopy-daemon.service - Hyper-V file copy service (FCOPY) daemon
   Loaded: loaded (/lib/systemd/system/hyperv-daemons.hv-fcopy-daemon.service; enabled; vendor preset: enabled)
   Active: inactive (dead)
Condition: start condition failed at 金 2015-11-06 22:31:17 JST; 3 days ago
$ systemctl status hyperv-daemons.hv-kvp-daemon.service
● hyperv-daemons.hv-kvp-daemon.service - Hyper-V key-value pair (KVP) daemon
   Loaded: loaded (/lib/systemd/system/hyperv-daemons.hv-kvp-daemon.service; enabled; vendor preset: enabled)
   Active: active (running) since 金 2015-11-06 22:31:17 JST; 3 days ago
 Main PID: 673 (hv_kvp_daemon)
   CGroup: /system.slice/hyperv-daemons.hv-kvp-daemon.service
           └─673 /usr/sbin/hv_kvp_daemon -n
$ systemctl status hyperv-daemons.hv-vss-daemon.service
● hyperv-daemons.hv-vss-daemon.service - Hyper-V volume shadow copy service (VSS) daemon
   Loaded: loaded (/lib/systemd/system/hyperv-daemons.hv-vss-daemon.service; enabled; vendor preset: enabled)
   Active: active (running) since 金 2015-11-06 22:31:17 JST; 3 days ago
 Main PID: 667 (hv_vss_daemon)
   CGroup: /system.slice/hyperv-daemons.hv-vss-daemon.service
           └─667 /usr/sbin/hv_vss_daemon -n
```

daemonのひとつで起動に失敗しているがとりあえず放置．それぞれの役割はこんな感じ．

> hv_fcopy_daemon provides the file copy service, allowing the host to copy files into the guest.
> hv_kvp_daemon provides the key-value pair (KVP) service, allowing the host to get and set the IP networking configuration of the guest. (This requires helper scripts which are not currently included.)
> hv_vss_daemon provides the volume shadow copy service (VSS), allowing the host to freeze the guest filesystems while taking a snapshot.

[Debian -- Details of package hyperv-daemons in sid](https://packages.debian.org/sid/hyperv-daemons)

今回必要なのはおそらく`hv_kvp_daemon`

## ホスト側のPowerShellでコマンドを実行

管理者権限がないと値を取得できないので注意

```shell
> Get-VMNetworkAdapter -VMName <VM Name> | Select IPAddresses
IPAddresses
-----------
{192.168.137.214, fe80::215:5dff:fe02:103}
```

以下のような感じでIPv4アドレスだけ取得できた

```shell
> $vm = Get-VMNetworkAdapter -VMName Phoebe
> $vm.IPAddresses -match "^\d+\.\d+\.\d+\.\d+$"
192.168.137.214
```

以上

{{< affiliate asin="4822253929" title="ひと目でわかるHyper-V Windows Server 2019版 (マイクロソフト関連書)" >}}
