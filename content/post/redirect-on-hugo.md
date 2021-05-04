+++
slug = ""
tags = []
title = "Hugoで特定ページをリダイレクトする"
date = "2021-05-04T20:05:25+09:00"

+++

Hugoで書いている本ブログのパスを変えたかった。静的サイトではできないんじゃないのと思っていたができたのでまとめておく。

<!--more-->

[Aliases | Hugo](https://gohugo.io/content-management/urls/#aliases)
方法はドキュメントに記載されている。記事ソースののFront Matterで`aliases`を定義すればよい。

``` toml
+++
slug = ""
tags = ["", ""]
title = "3Dプリンタ IUSE IUM1 を買った"
date = "2020-09-06T13:34:00+09:00"
aliases = ["/blog/3d-printer-1/"]      # /blog/3d-printer-1/から本来のURLへリダイレクトされる
+++
```

## 一括でソースを更新する

今回、自分は記事URLのPrefixを一括で変えたかったので、各ソースを一括で更新するスクリプトを書いた。

``` diff
--- a/config.toml
+++ b/config.toml
 [permalinks]
-  post = "/blog/:filename/"
+  post = "/post/:filename/"
```

旧URLには検索サイトからインデックスが貼られているので、旧URLから新URLへのリダイレクトを設定する。
以下のスクリプトで記事ソースにaliases行を追加していく。

``` bash
#!/bin/bash

for file in content/post/*.md; do
  filename=$(basename ${file})
  postname=${filename%.md}
  insert="aliases = [\"/blog/${postname}/\"]"
  sed -i "6i${insert}" ${file}
done
```

自分の場合は一律でファイルの6行目に挿入でよかったが、各ソースで行数が異なる場合はもう少し丁寧にsedのオプションを書く必要があるかもしれない。

以上

<iframe style="width:120px;height:240px;" marginwidth="0" marginheight="0" scrolling="no" frameborder="0" src="//rcm-fe.amazon-adsystem.com/e/cm?lt1=_blank&bc1=000000&IS2=1&bg1=FFFFFF&fc1=000000&lc1=0000FF&t=uyorum-22&language=ja_JP&o=9&p=8&l=as4&m=amazon&f=ifr&ref=as_ss_li_til&asins=B00WE7XZ68&linkId=df026cfd2306f9a1322b75e1aa7aa976"></iframe>
