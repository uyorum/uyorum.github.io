+++
categories = []
Tags = []
title = "RaspeberryPi用のGoogle製Web開発プラットフォームCoder for RaspberryPiを導入してみた"
date = "2013-10-06T11:20:00+09:00"

+++

先日リリースされたCoder for RaspberryPiを導入してみたのでその手順をまとめておきます．

<!--more-->

[こちら](http://googlecreativelab.github.io/coder/)の公式ページに手順が載っていますがいまいち説明不足でわかりにくいところもあったので
あらためて手順をまとめ直してみました．

# 用意するもの

1. RaspberryPi  
   これがないと始まりませんね．私はType.Bの方を使っています．
1. SDカード  
   公式では4GB以上を推奨しています．
1．インストーラ  
   [ここ](http://storage.googleapis.com/coder-images/coder_v0.4.zip)からzipをダウンロード・展開しておきます．
1. PC  
   Macだと楽にインストールできます．  
   Windowsの場合は[こちら](http://googlecreativelab.github.io/coder/#windows)を参考に．私はMacで導入したので詳しいことはわかりませんが．
1. ネットワーク  
   有線で接続するか，USB無線子機を用意します．
   私はPLANEXのGW-USValue-EZをたまたま持っていたのでこれを使いました．

# インストール

1. zipを展開してできたディレクトリ内の"CoderSetup"を実行します．  
   実行すると以下のウィンドウが表示されます．
   ![01](/coder-for-pi/01.jpg)
   表示されている通り，MacからSDカードを抜いた状態で"START"をクリックします．
1. MacにSDカードを挿入してから"NEXT"をクリックします．
   ![02](/coder-for-pi/02.jpg)
1. "INSTALL"をクリックしてSDカードにインストールします．SDカードはフォーマットされます．
   ![03](/coder-for-pi/03.jpg)
1. 以下の画面になったらインストール完了です．
   ![04](/coder-for-pi/04.jpg)
1. インストールが完了したらSDカードをRaspberryPiに挿入して起動させます．
   RaspberryPiが起動したら次は初期設定です．

# 初期設定
Coder for RaspberryPiの設定・操作はブラウザから行うことになります．
そのため，RaspberryPiをネットワークに接続する必要があるのですが，有線はもちろん無線にも対応しています．
私は前述の通りUSB無線子機を使って無線でセットアップを行ったので無線での手順を記載します．

1. PCの無線をONにしてネットワークを探します．  
   "CoderConfig"というアドホックネットワークが見つかるので接続します．
1. ブラウザで http://coder.local/ を開くと以下のページが表示されます．
   ![06](/coder-for-pi/06.jpg)
1. パスワードを設定します．  
   以後，このパスワードを使ってCoder for RaspberryPiの画面に入ることになります．
1. チュートリアルが表示されます．"Got it"をクリックして次へ進みます．
1. Coder for PaspberryPiのホームが表示されました．
   ![08](/coder-for-pi/08.jpg)
   以上で導入は完了です．

# 自宅の無線LANへ接続
今後いちいちアドホック接続するわけにもいかないので自宅の無線LANへ接続する設定を行います．
上の手順に続いてブラウザから設定します．

1. ホームの右上の歯車をクリックすると以下の画面になります．
   ![09](/coder-for-pi/09.jpg)
1. "Wifi Setup"をクリックしアクセスポイントのSSIDとパスワードを入力します．
1. 設定が完了すると自動的にRaspberryPiが再起動して無線LANに接続されているはずです．

あとはRaspberryPiのIPアドレスへブラウザで接続すればCoderの画面へ入れます．  
また無線LANの設定が完了すると自動でアドホック接続できなくなるようです．

# シャットダウンの方法
公式ページにも載っていなかったのですが，さすがにいきなりコンセントを抜いてしまうのはまずいと思って調べてみました．
RaspberryPiに以下の資格情報でSSH接続します．

* ユーザ：pi
* パスワード：Coder for RaspberryPiで設定したパスワード

ログインしたらshutdownコマンドを叩けばシャットダウンできます．  
ちなみにCoder for RaspberryPiの中身はRaspbianのようです．

以上です．
