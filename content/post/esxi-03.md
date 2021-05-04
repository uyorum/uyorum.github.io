+++
Categories = []
Tags = []
title = "Intel DC3217IYEへVMware vSphere hypervisor5.5をインストールする"
date = "2013-09-24T22:01:00+09:00"
aliases = ["/blog/esxi-03/"]

+++

先日購入したDC3217IYEにVMware vSphere hypervisorをインストールしようとしたところドライバがないと言われました．
IntelのNICだから認識するだろうとタカをくくっていましたがダメでした．方法を調べたので手順をまとめておきます．

<!--more-->

### 参考
[NanoLab – Running VMware vSphere on Intel NUC – Part 2](http://www.tekhead.org/blog/2013/01/nanolab-running-vmware-vsphere-on-intel-nuc-part-2-2/)

### 用意するもの
バージョンなどの番号は異なることがあります．適宜読みかえてください．

1. インストーラ(VMware-VMvisor-Installer-5.5.0-1331820.x86_64.iso)  
   ダウンロードにはVMwareのアカウントが必要です  
1. ESXi-Customizer(ESXi-Customizer-v2.7.1.exe)  
   [ここ](http://www.v-front.de/p/esxi-customizer.html)から最新版をダウンロードしておきます．
1. Intel 82579V Gigabit Ethernet Controllerのドライバ

### 作業
ダウンロードしたインストーラの中にドライバを組み込んで、新しいインストーラを作成します．

1. ESXi-Customizer-v2.7.1.exeを実行します．
1. 解凍する場所を指定します．(例: C:\tmp)
1. 解凍先のディレクトリにあるESXi-Customizer.cmdを実行します．ウィンドウが表示されるので以下の値を指定します．
   * ESXi ISO  
     ダウンロードしたESXiのインストーラを指定します
   * OEM.tgz  
     ダウンロードしたドライバを指定します
   * working directory  
     作成したインストーラの出力先ディレクトリを指定します．
1. 下のチェックボックスは以下のように選択します．
   * Force repackingを**選択**
   * Create (U)EFI-bootable ISOは**選択しない**
   * Enable automatic update checkは**選択しない**

1. 選択したら下の"Run!"をクリックして実行します．
   途中のダイアログは"はい"を選択します．

成功すると"working directory"に指定したディレクトリに"ESXi-5.x-Custom.iso"というファイルが作成されています．
あとはCDに焼くなり、USBメモリに焼くなりしてインストールをします．

以上、IntelのNUCベアボーンDC3217IYにVMware vSphere hypervisor5.5をインストールする方法(正確にはインストーラを作成する方法ですが)でした．  
実は別のショップで注文したSSDがまだ届いていないので実際にはインストールせずに、インストールの途中で"NICが見つからない"のエラーが出ないことを確認しただけです．
なのでインストール中、またはインストール後に何か不具合が発生するかもしれません．  
余談ですがvSphere5.5がリリースされていることを知ったのはこのためにインストーラをダウンロードしようとしたときのことでした．
