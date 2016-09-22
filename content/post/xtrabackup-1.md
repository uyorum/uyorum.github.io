+++
Categories = []
Tags = []
date = "2016-09-12T19:19:36+09:00"
title = "XtraBackupによるバックアップ設計"

+++

最近，自宅で動かしているとあるサービスのMariaDBのバックアップを取ろうとふと思い立った．
使ったことがなかったのでXtraBackupでバックアップ設計することにした．

<!--more-->

## 参考
* [Percona XtraBackup - Documentation](https://www.percona.com/doc/percona-xtrabackup/2.4/index.html)

## 設計方針
XtraBackupの使い方はネットに情報があふれているのでここでは説明しません．
こんな感じの方針でバックアップ設計をしていきます．

* バックアップ先はいずれかのクラウドがいいが，あまりお金をかけたくない(個人でやっているものなので)
* バックアップの容量をできるだけ小さくしたい
* RTOは数時間レベルでOK

XtraBackupは増分バックアップができるので以下のようにしました．

1. 1週間や2週間に1回くらいの頻度でフルバックアップを取得する
1. それ以外の日は前日からの増分バックアップを取得する

## コマンド

* フルバックアップ

        $ innobackupex --history=xbhistory --compact --stream=xbstream ./ | gzip - > base.xbstream.gz

* 増分バックアップ

        $ innobackupex --incremental --history=xbhistory --incremental-history-name=xbhistory --compact --stream=xbstream ./ | gzip - > inc.xbstream.gz

以下で各オプションの使用した理由などを解説していきます

### `--stream=xbstream`
[Make a Streaming Backup](https://www.percona.com/doc/percona-xtrabackup/2.4/howtos/recipes_ibkx_stream.html)

指定したパスにバックアップをファイルとして出力する代わりに，指定したフォーマットのアーカイブ形式で標準出力に吐き出します．
形式は`tar`と`xbstream`が指定できますが，`--incremental`オプションと組み合わせる場合は`xbstream`でなければならないので`xbstream`を使用します．

### `--history`
[Incremental Backups](https://www.percona.com/doc/percona-xtrabackup/2.4/xtrabackup_bin/incremental_backups.html)  
[Store backup history on the server](https://www.percona.com/doc/percona-xtrabackup/2.4/innobackupex/storing_history.html)

`--incremental`(増分バックアップ)を使うときは起点とするLSNを指定する必要があります．指定する方法は

* 前回のバックアップ先ディレクトリを指定する(`--incremantal-basedir`)
* 前回のLSNを指定する(`--incremental-lsn`)
* 前回のバックアップ時の情報を対象のDBに保存する(`--history`)

前回バックアップ時のLSNはバックアップ先ディレクトリの`xtrabackup_checkpoints`ファイルに記録されています(`to_lsn`)

    $ cat xtrabackup_checkpoints 
    backup_type = full-backuped
    from_lsn = 0
    to_lsn = 2353547498
    last_lsn = 2353547498
    compact = 0
    recover_binlog_info = 0

xbstream形式だと特定のファイルのみ展開したりすることができなさそうだし，今回は取得したバックアップはクラウド上にアップロードしてローカルからはすぐに削除するつもりなので，先2つの方法はとれなさそうです．
よって`--history`オプションを使用することにします．

`--history`を使用した場合，バックアップの情報は対象インスタンスの`PERCONA_SCHEMA.xtrabackup_history`に保存されます．

    $ innobackupex --history=xbhistory /data/backups
    $ mysql -uroot -ppassword
    > select * from PERCONA_SCHEMA.xtrabackup_history\G
    *************************** 1. row ***************************
                uuid: 3c60a347-78d8-11e6-95ea-06b838280a4d
                name: xbhistory
           tool_name: innobackupex
        tool_command: --history=xbhistory /data/backups
        tool_version: 2.3.5
    ibbackup_version: 2.3.5
      server_version: 5.5.50-MariaDB
          start_time: 2016-09-12 11:01:01
            end_time: 2016-09-12 11:01:20
           lock_time: 0
          binlog_pos: NULL
     innodb_from_lsn: 0
       innodb_to_lsn: 2353547508
             partial: N
         incremental: N
              format: file
             compact: N
          compressed: N
           encrypted: N

増分バックアップを取得するときは`--incremental-history-name`オプションを使います．
`--history`オプションを付けないとその回はDBに保存されないようなので増分バックアップのときも`--history`オプションを使います．
毎回，前回のフルバックアップからの増分を取得する，のようなバックアップ設計のときは`--history`オプションを付けないと実現できそうです．

### `--compact`
[Compact Backups](https://www.percona.com/doc/percona-xtrabackup/2.4/innobackupex/compact_backups_innobackupex.html)  
[漢(オトコ)のコンピュータ道: 知って得するInnoDBセカンダリインデックス活用術！](http://nippondanji.blogspot.jp/2010/10/innodb.html)

InnoDBのセカンダリインデックスをバックアップに含めない．
バックアップサイズは削減できるがセカンダリインデックスの再生成が必要になるためprepare処理に時間がかかってしまう．
今回はRTOよりもバックアップ容量を重視したいのでこのオプションを使用する．

### `--compress`
[Making a Compressed Backup](https://www.percona.com/doc/percona-xtrabackup/2.4/howtos/recipes_ibkx_compressed.html)

`innobackupex`コマンドには`--compress`というオプションがある．これを使うとバックアップ時に各`.ibd`ファイルを`qpress`という形式で圧縮するようになる．
`gzip`とどちらを使うのがいいのか，圧縮率と時間を比較してみた．

環境はEC2の`t2.micro`

|`--compress`|`gzip`|time|size|command|
|:--:|:--:|:--|:--|:--|
|N|N|16s|1020MB|innobackupex --stream=xbstream ./ > 1.xbstream|
|Y|N|16s|527MB|innobackupex --compress --stream=xbstream ./ > 2.xbstream|
|N|Y|66s|396MB|innobackupex --stream=xbstream ./ &#124; gzip - > 3.xbstream.gz|
|N|Y|25s|404MB|innobackupex --stream=xbstream ./ &#124; gzip -1 - > 4.xbstream.gz|
|Y|Y|47s|435MB|innobackupex --compress --stream=xbstream ./ &#124; gzip - > 5.xbstream.gz|

データの内容にもよるのだろうが，`--compress`オプションは結構高速で，オプションをつけないときと時間はほとんど変わらなかった．
だが，`gzip -1`だと時間は少しかかってしまうが，容量がさらに2割以上削減できるようなので`--compress`オプションは使用せずに`gzip -1`に渡すことにした．

### 最後に

mysqldumpと比べるとバックアップの容量が大きくなると思っていましたが，XtraBackupには増分バックアップ機能があるので結果的には容量を削減できそうです．
まだドキュメントをすべて読んだわけではないのでもっとよい方法があるのかもしれませんが，ひとまずこの方法で運用してみます．
