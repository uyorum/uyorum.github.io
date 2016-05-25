+++
Categories = []
Tags = []
title = "Octopressセットアップメモ"
date = "2015-02-22T22:16:12+09:00"

+++

わけあってOctopress環境を作り直したのでメモ

<!--more-->

## 参考資料
* [Octopress Documentation - Octopress](http://octopress.org/docs/)

## 前提

* Rubyはrbenvを使用してインストールする
    * 使用するバージョンは1.9.3-p551
    * rbenv-gemsetプラグインを使用してgemを隔離する

## 手順
1. ソースをclone

        $ git clone https://github.com/imathis/octopress
        Cloning into 'octopress'...
        remote: Counting objects: 10786, done.
        remote: Compressing objects: 100% (26/26), done.
        remote: Total 10786 (delta 8), reused 5 (delta 1)
        Receiving objects: 100% (10786/10786), 2.85 MiB | 1.68 MiB/s, done.
        Resolving deltas: 100% (5178/5178), done.
        Checking connectivity... done.
        $ ls
        octopress
        $ cd octopress

1. Rubyのバージョンを指定

        $ echo '1.9.3-p551' > .ruby-version
        $ rbenv versions
          system
        * 1.9.3-p551
  
1. gemsetを作成

        $ rbenv gemset create 1.9.3-p551 octopress
        created octopress for 1.9.3-p551
        $ echo octopress > .rbenv-gemsets
        $ rbenv gemset active
        octopress global

あとは公式の手順に従えばOK

自分の環境では途中でJavaScript Runtimeがないと怒られたので[ここ](https://github.com/imathis/octopress/issues/1612)を参考にGemfileに以下を追加

    # jekyll needs javascript runtime
    # detail: https://github.com/imathis/octopress/issues/1612
    gem 'therubyracer', '~> 0.12.1'

編集後に再び`bundle install`を実行．
