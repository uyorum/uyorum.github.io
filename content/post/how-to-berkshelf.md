+++
Categories = []
Tags = []
title = "最近のBerkshelfの使い方(2015)"
date = "2015-07-16T21:50:16+09:00"

+++

今さらながらBerkshelfを使ったのだけれどネットには最新の情報がなくて習得に手こずったのでまとめておく。

<!--more-->

## 参考
* [Berkshelf](http://berkshelf.com/)
* [Cookbookの管理を楽にするBerkshelfの使い方( ー`дー´)キリッ とか。 - 256bitの殺人メニュー](http://d.hatena.ne.jp/akuwano/20140806/1407291260)
* [最近の(2013/8/28時点の)vagrantとberkshelfの書き方 - Qiita](http://qiita.com/joker1007/items/1b62e3a36b4f435c53a2)

## インストール
chefdkパッケージに含まれている．Gemでもインストールできるがchefdkが推奨らしい．

## 設定
設定ファイルは~/.berkshelf/config.json  
ほとんどの設定は~/.chef/knife.rbから読み込んでくれる  
vagrant関連の項目を除いて，別個に設定が必要そうな項目は以下

* ssl.verify
* github

とりあえず`ssl.verify`だけは設定しておく．Chef Serverを使う場合はおそらく必須．

* ~/.berkshelf/config.json

        {
          "ssl": {
            "verify": false
          }
        }

## 考え方
* BerkshelfはRubyにおけるBundlerの役割
    * アプリケーション(=cookbook)を動かすのに必要なGem(=cookbook)をインストール(=ダウンロード)する
* Gemfile(=Berksfile)はアプリケーション(=cookbook)に紐づく
    * chef-repoではない
* Gem同様，cookbookはローカルにインストールする
    * レシピを開発する個々の環境で`berks install`する
    * Berkshelfでダウンロードするcookbookはchef-repoに含めない

## コマンドの流れ
1. Berksfileを作成する
    * 既存のcookbookにBerksfileを作成する

            $ cd cookbook_name
            $ berks init .
                  create  Berksfile
                  create  Thorfile
                  create  chefignore
                  create  .gitignore
                  create  Gemfile
                  create  .kitchen.yml
                  append  Thorfile
                  create  test/integration/default
                  append  .gitignore
                  append  .gitignore
                  append  Gemfile
                  append  Gemfile
            You must run `bundle install' to fetch any new gems.
                  create  Vagrantfile
            Successfully initialized

    * 新規にcookbookを作成する

            $ berks cookbook test
                  create  test/files/default
                  create  test/templates/default
                  create  test/attributes
                  create  test/libraries
                  create  test/providers
                  create  test/recipes
                  create  test/resources
                  create  test/recipes/default.rb
                  create  test/metadata.rb
                  create  test/LICENSE
                  create  test/README.md
                  create  test/CHANGELOG.md
                  create  test/Berksfile
                  create  test/Thorfile
                  create  test/chefignore
                  create  test/.gitignore
                  create  test/Gemfile
                  create  .kitchen.yml
                  append  Thorfile
                  append  .gitignore
                  append  .gitignore
                  append  Gemfile
                  append  Gemfile
            You must run `bundle install' to fetch any new gems.
                  create  test/Vagrantfile

        カレントディレクトリにcookbookが作成される

    今後は`knife cookbook create`の代わりに`berks cookbook`でcookbookを作成するようにするとよい．

1. Berksfileに依存するcookbook名を書いていく
    書き方はGemfileと同様．

        source "https://supermarket.chef.io"
         
        metadata
         
        cookbook 'mysql2_chef_gem', '~> 1.0.1'
        cookbook 'database', '~> 4.0.6'

1. metadata.rbにも同じcookbook名を書く

        depends          'mysql2_chef_gem'
        depends          'database'

1. cookbookをインストール

        $ berks install

    デフォルトでは`~/.berkshelf/cookbooks/<cookbook_name>-<version>`にcookbookが格納される．  
    ネットにある記事では`chef-repo/cookbooks`にインストールすると書かれていることがあるが，現在は違う模様．

1. Chef Serverへアップロード

        $ berks upload [cookbook_name]
        またはcookbookディレクトリの中で
        $ berks upload

    Berkshelfでインストールしたcookbookのディレクトリ名がcookbook名と異なるためそのままでは`knife`でuploadできない．注意．  
    cookbook名を入れないと依存するcookbookも一緒にuploadしてくれる

## metaなcookbook
Berkshelfでインストールしたcookbookを使いたい場合，run_listに直接書くのではなくそのcookbookを呼び出す用のcookbookを用意しておくとよい．  
そのcookbookでコミュニティのcookbookのAttributeを上書きとかして，include_recipeする．  
で，Berksfileに使うcookbookを書いていく．  
[最近の(2013/8/28時点の)vagrantとberkshelfの書き方 - Qiita](http://qiita.com/joker1007/items/1b62e3a36b4f435c53a2)を参考に．

## その他のコマンド
* `berks package`  
cookbookとその依存cookbookをまとめてtar.gzでアーカイブする
* `berks vendor`  
上記と似ているが，アーカイブせずに`pwd/berks-cookbooks`以下にcookbookを配置する  
ディレクリ名=cookbook名にして配置してくれるのでときどき使う．PackerでChef使うときとか．

## 感想
Productionな環境ではコミュニティのcookbookはあまり使用しないみたいなので，Berkshelfの出番はあまりないと思う．  
ごく簡単なものや特に便利なものに関してはコミュニティのものを使ってもいいと思うけど，多様してブラックボックスが増えるのもよくない．  
主にインスタントな検証環境，開発環境とかかな．
