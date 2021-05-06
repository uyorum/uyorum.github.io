+++
date = "2017-03-01T23:01:28+09:00"
slug = ""
title = "Ruby on RailsのAsset Pipelineとインクルードとプリコンパイルの動作"
tags = ["Ruby", "Ruby on Rails"]
aliases = ["/blog/rails-asset-pipeline-1/"]

+++

Ruby on RailsのAsset Pipelineについて取り組む機会があったが，動きをよくわかっていなかったため解決までに非常に多くの時間をかけてしまった．
いろいろと知識を詰め込んだので復習も兼ねてまとめていく．
おそらくRailsを使い慣れている人にとっては基本的すぎる内容．

<!--more-->

## 環境

``` shell
$ ruby -v
geruby 2.4.0p0 (2016-12-24 revision 57164) [x86_64-darwin15]
$ gem list -l ^rails$

*** LOCAL GEMS ***

rails (4.2.8)
```

## アセットとは

定義が見つからなかったが，おそらく以下のような感じ．

    Railsのサーバから配信するコンテンツのうち，Viewにより生成されたもの以外

具体的にはJavaScript，CSS，画像ファイルなど．あまりないだろうが，静的なhtmlもこれらと同様に扱うことはできそう．

## アセットパイプラインとは

サーバ上に存在するアセットをクライアントへ配信する仕組みのこと．アセットパイプラインは`sprockets-rails`gemにより提供されている．配信までの途中でいくつかの処理を経る場合がほとんど．例えば以下．

* JavaScriptおよびCSSの結合，最小化
* ブラウザが理解しない書式(CoffeeScript, SASS, ERBなど)で書かれたコードを素のコードへ変換する
* ファイル名へMD5ダイジェストの付与
* アセットの圧縮

それぞれの処理の内容は[アセットパイプライン | Rails ガイド](https://railsguides.jp/asset_pipeline.html)が詳しいので省略する

いくつかの処理はRailsが動作するモード(Environment)により異なる．

通常，アセットは`{app,lib,vendor}/assets/{javascripts,stylesheets,images}`のいずれかに配置する．
それぞれの使い分けは下記を参照  
[2.2 アセットの編成 - アセットパイプライン | Rails ガイド](https://railsguides.jp/asset_pipeline.html#%E3%82%A2%E3%82%BB%E3%83%83%E3%83%88%E3%81%AE%E7%B7%A8%E6%88%90)

以下，簡単のため`config.assets.digest = false`を設定する(ファイル名にダイジェストが含まれなくなる)

## インクルード

通常，クライアントへ配信されるのは`app/assets/javascripts/application.js`と`app/assets/stylesheets/application.css`である．
実際，デフォルトの内容を削除してみると，レスポンスに含まれるstylesheetとscriptは`application.css`および`application.js`のみである．

``` shell
$ cat /dev/null > app/assets/javascripts/application.js
$ cat /dev/null > app/assets/stylesheets/application.css
$ rails s &
$ curl localhost:3000
<!DOCTYPE html>
<html>
<head>
  <title>PlayRubyOnRails</title>
  <link rel="stylesheet" media="all" href="/assets/application.self.css?body=1" />
  <script src="/assets/application.self.js?body=1"></script>
  <meta name="csrf-param" content="authenticity_token" />
<meta name="csrf-token" content="y6ytycY6X3PLUW5E6YTxIcEAC9CovDLYNqdipEqLvE/GXPGQIVq2LRvMMSQvauxmmVNEVvwlhSp3cQ1je+HWVw==" />
</head>
<body>

<h1>Sample Page</h1>


</body>
</html>
```

ただし特別な文法により，これらのファイルに別のファイルを`挿入`することができる．
例として以下の`example_script.js`と`example_style.css`をそれぞれ`application.js`と`application.css`に挿入する．

``` shell
echo '// example_script.js' >  vendor/assets/javascripts/example_script.js
echo '/* example_style.css */' > vendor/assets/stylesheets/example_style.css
```

* app/assets/javascripts/application.js

``` javascript
//= require example_script
```

* app/assets/stylesheets/application.css

``` css
/*
 *= require example_style
 */
```

サーバからのレスポンスは以下のように変わる

``` shell
$ curl localhost:3000
<!DOCTYPE html>
<html>
<head>
  <title>PlayRubyOnRails</title>
  <link rel="stylesheet" media="all" href="/assets/example_style.self.css?body=1" />
<link rel="stylesheet" media="all" href="/assets/application.self.css?body=1" />
  <script src="/assets/example_script.self.js?body=1"></script>
<script src="/assets/application.self.js?body=1"></script>
  <meta name="csrf-param" content="authenticity_token" />
<meta name="csrf-token" content="gbwYN47/sxpRHGPNzTr0hSqyDnZJL2L21r+9R77Inc3ytUyGKTjhpXe9JYKdafnLgXqaYUdEKqJgtwSvNt8Qmg==" />
</head>
<body>

<h1>Sample Page</h1>


</body>
</html>
```

`example_style.css`と`example_script.js`が追加されている．それぞれの内容も先ほど作成した通りである

``` shell
$ curl 'localhost:3000/assets/example_style.self.css?body=1'
/* example_style.css */

$ curl 'localhost:3000/assets/example_script.self.js?body=1'
// example_script.js
```

以上がインクルード機能である．なおインクルード対象のアセットの探索場所はあらかじめ設定されており，`Rails.application.config.assets.paths`で確認することができる．
確認したところ，`Rails.root`とGemのインストールディレクトリ以下の`{app,lib,vendor}/assets/{javascripts,stylesheets,images}`が追加されていた．

なお当然ながらインクルードを利用せずにクライアントへ配信することも可能である．記述方法は[2.3 アセットにリンクするコードを書く - アセットパイプライン | Rails ガイド](https://railsguides.jp/asset_pipeline.html#%E3%82%A2%E3%82%BB%E3%83%83%E3%83%88%E3%81%AB%E3%83%AA%E3%83%B3%E3%82%AF%E3%81%99%E3%82%8B%E3%82%B3%E3%83%BC%E3%83%89%E3%82%92%E6%9B%B8%E3%81%8F)を参照．

以上のように，RailsはAssets Pipelineにより動的にアセットを処理しレスポンスを生成する．
ただし，以上の動作はRailsをdevelopment環境で動作させた場合であり，production環境で動作させた場合は多少動作が異なる．
production環境では動的にアセットを処理することはなく，事前にアセットを静的に生成しておく必要がある．この処理をプリコンパイルと呼ぶ．
`config.assets.compile = true`とすることによりdevelopment環境と同様の動作にすることはできるが，サーバ側のパフォーマンスの観点から通常この設定は使用しない．

## プリコンパイル

RailsをProdution環境で動作させるには事前にプリコンパイルを行なう必要がある．そのためのRakeタスクがあらかじめ用意されており，コマンドひとつでプリコンパイルは完了する．

* app/assets/javascripts/application.js

``` javascript
//= require example_script
var application = foo;
```

* app/assets/javascripts/example_script.js

``` javascript
// example_script.js
var example_script = bar;
```

* app/assets/stylesheets/application.css

``` css
/*
 *= require example_style
 */
h1 {
  font-size: 3em;
}
```

* app/assets/stylesheets/example_style.css

``` css
/* example_style.css */
h2 {
  font-size: 1.2em;
}
```

``` shell
$ RAILS_ENV=production bundle exec rake assets:precompile
I, [2017-03-05T16:32:17.543841 #10704]  INFO -- : Writing /Users/uyorum/play-ruby-on-rails/public/assets/application-042541b182c1e31682c8f168530408629e368ed21820dbd49b2e78e2aeccaa01.js
I, [2017-03-05T16:32:17.550791 #10704]  INFO -- : Writing /Users/uyorum/play-ruby-on-rails/public/assets/application-042541b182c1e31682c8f168530408629e368ed21820dbd49b2e78e2aeccaa01.js.gz
I, [2017-03-05T16:32:17.558124 #10704]  INFO -- : Writing /Users/uyorum/play-ruby-on-rails/public/assets/application-0938fa3aeba7c1cd9ed012d1f09d5ace12fd64a5a6f295b2e326f86403e53aff.css
I, [2017-03-05T16:32:17.558406 #10704]  INFO -- : Writing /Users/uyorum/play-ruby-on-rails/public/assets/application-0938fa3aeba7c1cd9ed012d1f09d5ace12fd64a5a6f295b2e326f86403e53aff.css.gz
```

なお，`config.assets.digest = false`を設定しているにも関わらずファイル名にダイジェストが含まれてしまうのは仕様のようだ．[^1]

production環境でRailsを起動してアクセスしてみるとレスポンスは以下のようになっている．(環境変数`SECRET_KEY_BASE`と`RAILS_SERVE_STATIC_FILES`についての説明はここでは省略する．)

``` shell
$ RAILS_ENV=production SECRET_KEY_BASE=secret RAILS_SERVE_STATIC_FILES=1 rails s &
$ curl localhost:3000
<!DOCTYPE html>
<html>
<head>
  <title>PlayRubyOnRails</title>
  <link rel="stylesheet" media="all" href="/assets/application-0938fa3aeba7c1cd9ed012d1f09d5ace12fd64a5a6f295b2e326f86403e53aff.css" />
  <script src="/assets/application-042541b182c1e31682c8f168530408629e368ed21820dbd49b2e78e2aeccaa01.js"></script>
  <meta name="csrf-param" content="authenticity_token" />
<meta name="csrf-token" content="yuRwf5qcdQ81DfCqhYLYItnc7p6RR52Ny5zahm0vrFuL4p6EFVOPOvjtg25PrjTa4OfybypUlqH6cbra4cuqjA==" />
</head>
<body>

<h1>Sample Page</h1>


</body>
</html>
```

development環境ではインクルードしたアセットが列挙されていたが，今回は`application.css`と`application.js`だけになっている．
インクルードした`example_script.js`と`example_style.css`はこれらのファイルに挿入されてクラアントへ配信される．

``` shell
$ curl localhost:3000/assets/application-0938fa3aeba7c1cd9ed012d1f09d5ace12fd64a5a6f295b2e326f86403e53aff.css
h2{font-size:1.2em}h1{font-size:3em}
$ curl localhost:3000/assets/application-042541b182c1e31682c8f168530408629e368ed21820dbd49b2e78e2aeccaa01.js
var example_script=bar,application=foo;
```

ちなみに，単にファイルの内容を結合するだけでなく，以下のような処理が施されているのがわかる．

* 不要な改行，空白の削除
* コメントの削除
* 記述の結合

これが，冒頭で述べたAssets Pipelineが行う処理のひとつ，最小化である．

## config.assets.precompile

`application.js`と`application.css`にインクルードしてアセットを配信するのならこれでよいのだが，そうでない場合(特定のページでだけでアセットを配信したい場合など)は注意が必要である．
例として`application.js`にはインクルードしないJavaScriptコード(`addon_script.js`)をひとつ追加して`application.html.erb`にエントリを追加する

* app/assets/javascripts/addon_script.js

``` javascript
var addon_script = hoge;
```

* app/views/layouts/application.html.erb

``` html
<!DOCTYPE html>
<html>
<head>
  <title>PlayRubyOnRails</title>
  <%= stylesheet_link_tag    'application', media: 'all' %>
  <%= javascript_include_tag 'application' %>
  <%= javascript_include_tag 'addon_script' %>
  <%= csrf_meta_tags %>
</head>
<body>

<%= yield %>

</body>
</html>
```

このとき，development環境では`addon_script.js`はアセットの探索パスに含まれているため正常に配信されるのだが，このファイルは実はプリコンパイルされないためproduction環境では配信されない．

``` shell
$ RAILS_ENV=production bundle exec rake assets:precompile
(何も出力されない)
```

なぜこのようなことが起こるかというと，Assets Pipelineにはインクルードされたアセットの探索パス(`config.assets.paths`)とは別にプリコンパイル対象とするアセットの探索パスが設定されているためである．
デフォルトではプリコンパイルは`app/assets`以下の`.js`，`.css`(`addon_script.js`はこれに合致する)**以外**のファイルが対象となっている．それ以外のファイルをプリコンパイル対象としたい場合は`config.assets.precompile`で指定する必要がある．(デフォルトだと`config/initializers/assets.rb`に書くことになっている)

``` shell
# addon_script.js をプリコンパイル対象に追加
$ echo 'Rails.application.config.assets.precompile += %w( addon_script.js )' >> config/initializers/assets.rb
$ RAILS_ENV=production bundle exec rake assets:precompile
I, [2017-03-05T17:19:41.045142 #45578]  INFO -- : Writing /Users/uyorum/play-ruby-on-rails/public/assets/addon_script-1a95c29effd76a7a053372381062d1ff547d51609534712aa469e4682fe94f39.js
I, [2017-03-05T17:19:41.051197 #45578]  INFO -- : Writing /Users/uyorum/play-ruby-on-rails/public/assets/addon_script-1a95c29effd76a7a053372381062d1ff547d51609534712aa469e4682fe94f39.js.gz
```

`addon_script.js`がプリコンパイルされた．

以上のように，アセットの探索パスには含まれているが，プリコンパイルの対象ではないファイル(`application.js`や`application.css`にインクルードしていない`.js`や`.css`)がある場合は注意が必要である．(開発環境では正常に動いているが，本番環境で異常が発生してしまう)  
私の場合はこの挙動の違いに気づくまで時間がかかってしまった…

以上

ここで使用したコードは[uyorum/play-ruby-on-rails at assets-pipeline](https://github.com/uyorum/play-ruby-on-rails/tree/assets-pipeline)で公開している．

## 参考

* [アセットパイプライン | Rails ガイド](https://railsguides.jp/asset_pipeline.html)  
    とりあえずここ読んどけばいいかな，と思って読んだが実際に触ってみないと細かいところがわからなかった
* [アセットパイプライン(Asset Pipeline) - - Railsドキュメント](http://railsdoc.com/asset_pipeline)
* [Rails Asset Pipelineがうまくいかないときの問題の切り分けかた - Qiita](http://qiita.com/metheglin/items/c5c756246b7afbd34ae2)
* [Only compile non-js/css under app/assets by default by josh · Pull Request #7968 · rails/rails](https://github.com/rails/rails/pull/7968)

[^1]: [Rails4のdigestにまつわる論争 - Qiita](http://qiita.com/munazo/items/15f9c143bc4ecdd74220)

{{< affiliate asin="4297114623" title="パーフェクト Ruby on Rails 【増補改訂版】 (Perfect series)" >}}
