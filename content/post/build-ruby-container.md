+++
slug = ""
tags = ["Ruby", "Docker"]
title = "CentOSベースのRubyコンテナイメージを作成する"
date = "2021-05-06T15:07:29+09:00"
+++

Rubyがインストールされたコンテナイメージが欲しかったのでメモ。

<!--more-->

## 背景

そもそもRubyのコンテナイメージはDocker公式が配布している。  
[DockerHub](https://hub.docker.com/_/ruby)

しかし、これらのイメージはベースがDebianやAlpine Linux、Ubuntuとなっている。
とある理由でCentOSがベースのRubyコンテナが欲しかったので自分でビルドすることにした。

## Dockerfile

コンテナでない環境なら普段はrbenvとruby-buildを使ってRubyをインストールするのだが、コンテナではRubyをひとつしか入れないのでrbenvは不要。  
コンテナにはできるだけ余計なものを入れたくないため、はじめは自分でRubyをビルドしようとしたのだが、思いのほか複雑になってしまう。  
よい方法がないかしばらく調べた結果、ruby-buildを単独で使えばよいことがわかった。  
（というかruby-buildはrbenvと一緒に使うものという認識だったので、それ単独で使えるとは思っていなかった）

よくよく見てみるとReadmeに普通に書いてある。  
[rbenv/ruby-build: Compile and install Ruby](https://github.com/rbenv/ruby-build)

Dockerfileは以下のようになる。

``` dockerfile
FROM centos:7

RUN yum install -y git make gcc bzip2 openssl-devel libyaml-devel libffi-devel readline-devel zlib-devel gdbm-devel ncurses-devel && \
  git clone https://github.com/rbenv/ruby-build.git && \
  PREFIX=/usr/local ./ruby-build/install.sh

ENV GEM_HOME=/tmp/gems
VOLUME ${GEM_HOME}

ENV RUBY_VERSION=2.7.3
ENV RUBY_DIR=/usr/local/ruby-${RUBY_VERSION}
RUN /usr/local/bin/ruby-build ${RUBY_VERSION} ${RUBY_DIR}

ENV PATH=/tmp/gems/bin:${RUBY_DIR}/bin:${PATH}

CMD irb
```

以下のように設計してある。

* コマンドを与えない場合、irbが起動するようにしている
* Gemはコンテナ内の`/tmp/gems`へインストールされる
* このディレクトリをホストへ外出しすることで、コンテナを作り直してもGemを保持できる

おそらくruby-buildやビルドのためにインストールしたパッケージはRubyを動かすこと自体には不要なので、
Multi stage buildを使えばイメージサイズをもっと小さくできそう。それはまたの機会に実施することにする。

---

これを書いたあとにCentOSプロジェクトがCentOS 7ベースのRubyコンテナをいくつか公開していることに気づいてしまった……。  
OpenShiftのS2Iビルド用のイメージだが、おそらくそれ以外の用途にも使えそう。  
[centos/ruby-27-centos7](https://hub.docker.com/r/centos/ruby-27-centos7)

とはいえパッチバージョンまで指定したい場合は自作するしかなさそう。

---

## 追記
Multi stage buildを使ってDockerfileを書き直した。  
ついでにRubyのバージョンをBuild argにすることでビルド時に外部から与えることができるように変更。  
イメージのサイズは140MBほど減って391MBになった。

{{< gist uyorum be8616c86dd1cdbf9bd06aa7145f1646 >}}


{{< affiliate asin="4873117763" title="Docker" >}}
