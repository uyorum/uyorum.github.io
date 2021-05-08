+++
slug = ""
tags = ["Hugo", "ブログ"]
title = "Hugoで特定ページをリダイレクトする"
date = "2021-05-04T20:05:25+09:00"

+++

Hugoで書いている本ブログのパスを変えたかった。静的サイトではできないんじゃないのと思っていたができたのでまとめておく。

<!--more-->

[Aliases | Hugo](https://gohugo.io/content-management/urls/#aliases)
方法はドキュメントに記載されている。記事ソースののFront Matterで`aliases`を定義すればよい。

``` ini {hl_lines=[6]}
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

{{< affiliate asin="4844396617" title="6日間で楽しく学ぶLinuxコマンドライン入門 (ネット時代の、これから始めるプログラミング（NextPublishing）)" >}}
