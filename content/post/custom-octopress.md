+++
Categories = []
Tags = []
title = "Octopressでmarkdownのファイル名規則を変更する"
date = "2014-04-22T23:10:00+09:00"

+++

少しいじりました．

<!--more-->

## 参考

*  [OctopressのRakefileのカスタマイズ](http://blog.awairo.net/blog/2014/01/01/customizing-octopress-rakefile/)

## 拡張子を.mdにする
拡張子がmarkdownて長すぎると思うので．  
Rakefileを編集

        % diff -u Rakefile.bak Rakefile
        --- Rakefile.bak	2014-04-20 23:00:27.660893177 +0900
        +++ Rakefile	2014-04-20 23:01:19.592893607 +0900
        @@ -23,8 +23,8 @@
         stash_dir       = "_stash"    # directory to stash posts for speedy generation
         posts_dir       = "_posts"    # directory for blog files
         themes_dir      = ".themes"   # directory for blog files
        -new_post_ext    = "markdown"  # default new post file extension when using the new_post task
        -new_page_ext    = "markdown"  # default new page file extension when using the new_page task
        +new_post_ext    = "md"        # default new post file extension when using the new_post task
        +new_page_ext    = "md"        # default new page file extension when using the new_page task
         server_port     = "4000"      # port for preview server eg. localhost:4000

## ディレクトリ掘る
_posts/YYYY/MM/にディレクトリを掘って.mdを保存する  
上と同様Rakefileを編集

        % diff -u Rakefile.bak Rakefile
        @@ -98,8 +98,9 @@
             title = get_stdin("Enter a title for your post: ")
           end
           raise "### You haven't set anything up yet. First run `rake install` to set up an Octopress theme." unless File.directory?(source_dir)
        -  filename = "#{source_dir}/#{posts_dir}/#{Time.now.strftime('%Y-%m-%d')}-#{title.to_url}.#{new_post_ext}"
        +  post_dir = "#{source_dir}/#{posts_dir}/#{Time.now.strftime('%Y')}/#{Time.now.strftime('%m')}"
        +  mkdir_p post_dir
        +  filename = "#{post_dir}/#{Time.now.strftime('%Y-%m-%d')}-#{title.to_url}.#{new_post_ext}"
           if File.exist?(filename)
             abort("rake aborted!") if ask("#{filename} already exists. Do you want to overwrite?", ['y', 'n']) == 'n'
           end
