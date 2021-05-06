+++
Categories = []
Tags = ["Android", "Linux", "Debian"]
title = "Android上でDebianを動かす"
date = "2013-09-20T22:44:00+09:00"
aliases = ["/blog/debian-on-android/"]

+++

AndroidでもEmacsと戯れたかったので調べてみました．

<!--more-->

## 参考
- [ChrootOnAndroid](http://wiki.debian.org/ChrootOnAndroid)
- [androidのSDカード領域にDebian squeezeのchroot環境を入れる](http://j7lg.tumblr.com/post/18547622412/android-sd-debian-squeeze-chroot)
- [Android+ポケモンキーボードでモバイルLinux環境を作る](http://d.hatena.ne.jp/Strobo/20120607/1339065529)
- [AndroidでDebian Lennyを使う。](http://d.hatena.ne.jp/rattcv/20101219)

## 方針
ざっと調べてみた感じ導入には次の二通りの方法があるようです．

1. イメージファイルを作って，その中にルートファイルシステムを構築
2. Android端末またはSDカード内にディレクトリを掘って，その中にルートファイルシステムを構築

どちらの場合も作ったルートファイルシステムにchrootすることでDebian環境に移行します．  
今回は1の方法を選択しました．  
理由は環境のバックアップがファイルひとつをコピーすればいいという点です．

## 用意するもの
* Debian環境  
  Debianのイメージファイルを作成するのに必要です．  
  物理マシンでも仮想マシンでも可能ですが，作成したイメージファイルをAndroid実機のストレージ内にコピーできる環境である必要があります．
* Android実機  
  ルート権限が必要です．
  また，作成したイメージファイルを保存するためのストレージ容量が必要です．  
  場所は内蔵でもSDカードでもよいはずです．自分はSDカードがささる端末を持っていないので未確認ですが．

## 作業内容
### Debianイメージファイルの作成
800MBのイメージファイルを作成します．Debian実機で以下のコマンドを実行します．
800MB * 1024 * 1024 = 838860800B なので 838860800バイトのファイルを作ればいいことになります．

        # aptitude install debootstrap
        # dd if=/dev/zero of=debian.img seek=838860800 bs=1 count=1
        # mke2fs -F debian.img
        # mkdir debian
        # sudo mount -o loop debian.img debian
        # sudo debootstrap --verbose --arch=armel --foreign squeeze debian http://ftp.jp.debian.org/debian

### Androidでmountしてchroot
* PC上で作業  
  Androidのストレージ上に作成したイメージファイルをコピーします．ここではadbコマンドを使用します．  
  Android SDKの導入方法は各自で調べてください．

        イメージファイルを/sdcard/へコピー
        # adb push debian.img /sdcard/
        Androidのシェルへ移動
        # adb shell
        
* Android上で作業

        はじめにrootへ昇格します
        $ su
        # cd /sdcard
        # mkdir debian
        # busybox mknod /dev/block/loop99 b 7 0
        # busybox losetup /dev/block/loop99 debian.img
        # busybox mount -t ext2 -o noatime,nodiratime /dev/block/loop99 debian
        # busybox chroot debian /bin/bash
        
### chroot環境下で作業

        # /debootstrap/debootstrap --second-stage
        # echo 'deb http://ftp.jp.debian.org/debian stable main non-free contrib' > /etc/apt/sources.list
        # apt-get autoclean
        # apt-get update

### Debianの設定
以上でDebianのインストールは完了しました．あとはいろいろ必要な設定を行なっていきます．
#### 設定ファイルの編集
* /etc/resolv.conf

        nameserver 8.8.8.8
        nameserver 8.8.4.4
  
* /etc/hosts

        127.0.0.1       localhost
  
* /etc/sysctl.d/ipv6.conf

        net.ipv6.conf.all.disable_ipv6 = 1
        
#### 各種設定
* localeの設定

        apt-get install locales
        dpkg-reconfigure locales
  
* とりあえず使いそうなパッケージを入れる
  ここは各自必要なものをインストールしてください．
  ここで入れる必要のあるパッケージはとくにありません．

        aptitude install emacs23-nox vim lv git-core zsh ddskk migemo ruby
  
### bootscriptを配置
以上で必要な作業は完了しました．Debianを起動するには適当なターミナルアプリでchrootコマンドを叩けばいいのですが，
その前にexportとかmountとかいろいろコマンドを実行しなくてはいけません．  
これはなかなか面倒なので起動に必要な処理をスクリプトにまとめておきます．  
以下のスクリプトは参考サイトから拝借しました．

- bootdebian.sh

       #!/system/bin/sh
        
       abort() {
           echo $1
           exit 1
       }
        
       DEBIAN=/sdcard/debian.img
        
       [ -f ${DEBIAN} ] || abort "${DEBIAN}: no such file."
           DEVICE=/dev/block/loop99
       [ -b ${DEVICE} ]
           DEBROOT=/sdcard/debian
       [ -d ${DEBROOT} ] || mkdir -p ${DEBROOT}
           export PATH=/system/bin:/usr/bin:/usr/sbin:/bin:$PATH
           export TERM=linux
           export HOME=/root
           export LANG=ja_JP.UTF-8
           
       busybox mknod ${DEVICE} b 7 99; busybox losetup ${DEVICE} ${DEBIAN}; sleep 1
       busybox mount -t ext2 -o noatime,nodiratime ${DEVICE} ${DEBROOT}/
        
       if [ $? == 0 ]; then
           sleep 1
           echo -n "Debian boot..."
           busybox mount -t devpts devpts ${DEBROOT}/dev/pts; sleep 1
           busybox mount -t proc proc ${DEBROOT}/proc; sleep 1
           busybox mount -t sysfs sysfs ${DEBROOT}/sys; sleep 1
           echo "done"
           chroot ${DEBROOT} /bin/zsh; sleep 1
           echo -n "Shutdown..."
           busybox fuser -k ${DEBROOT}; sleep 1
           busybox fuser -k ${DEVICE}; sleep 1
           busybox umount ${DEBROOT}/dev/pts; sleep 1
           busybox umount ${DEBROOT}/proc; sleep 1
           busybox umount ${DEBROOT}/sys; sleep 1
           busybox umount ${DEBROOT}
           rm ${DEVICE}
           echo "done"
       else
           echo "Debian boot error."
           busybox fuser -k ${DEBROOT}; sleep 1
           busybox fuser -k ${DEVICE}; sleep 1
           busybox umount ${DEBROOT}/dev/pts; sleep 1
           busybox umount ${DEBROOT}/proc; sleep 1
           busybox umount ${DEBROOT}/sys; sleep 1
           busybox umount ${DEBROOT}
           rm ${DEVICE}
       fi

私はzshユーザなのでシェルをzshにしていますが，そうでない人は適当に指定してください．
スクリプトを作成したら以下のコマンドでAndroid端末の/sdcard/以下にコピーします．

        $ adb push bootdebian.sh /sdcard/

## 起動してみる
適当なターミナルアプリからRoot権限で上のスクリプトを走らせればDebianが起動します．
私は[Android Terminal Emulator](https://play.google.com/store/apps/details?id=jackpal.androidterm&hl=ja)というアプリを使っています．
アプリを起動したら以下のコマンドを実行します．

        $ su
        # sh /sdcard/bootdebian.sh

プロンプトが返ってきたらDebianが起動しているはずです．
