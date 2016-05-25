+++
Categories = []
Tags = []
title = "org-googlecl.elの導入と改造"
date = "2013-09-21T09:55:00+09:00"

+++

EmacsからBloggerに直接投稿できる上にorg-modeの文法が利用できるorg-googlecl.elをむかし導入しました．
さっそく試してみたところ文章がやたらと改行されていたのでそれを直すためにorg-googlecl.elを改造しました．
そのログが残っていたのでとりあえずあげておきます．
見てのとおり現在は見ての通りgithub + Octopressを使用しているのですが．

<!--more-->


## 導入
Android上でEmacsが動くようになったので，そこからbloggerに投稿するために以前友人に教えてもらったorg-googlecl.elを導入しました．  
方法は[ここ](http://hitsumabushi-pc.blogspot.jp/2011/12/org-googleclel.html)や[ここ](http://kikukawatei.blogspot.jp/2011/01/org-googleclel-blogger_4570.html)を参考にすれば難しくないので割愛します．

## 改造
早速試してみたのですが，文章がやたらと改行されてしまって見ににくいことこの上ない．  
いろいろ調べたり試したりしたところ，orgから生成したhtmlをアップロードするときにソース内の改行を"<br />"に置換している模様．  
どうしてこんなことになっているのかは不明ですが，とりあえずupload時にソース内の改行をすべて消してしまうことにします．  
自分はelispを読み書きできないので[ここ](http://kikukawatei.blogspot.jp/2011/01/org-googleclel.html)を参考org-googlecl.elを編集します．

        (with-temp-file  tmpfile
            (insert bhtml)
            (goto-char (buffer-end 1))
            (insert googlecl-footer))

の部分を

        (with-temp-file  tmpfile
                (insert (replace-regexp-in-string
                         "\n" "" bhtml))
                         (goto-char (buffer-end 1)))

と置き換えました．  
"\n"(改行コード)を""で置換しています．(つまり\nを削除)  
とりあえずこれで読める体裁にはなりました．


