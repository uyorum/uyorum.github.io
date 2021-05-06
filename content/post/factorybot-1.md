+++
date = "2017-12-29T17:17:00+09:00"
slug = ""
tags = ["Ruby", "RSpec", "FactoryBot"]
title = "FactoryBotでテストのはじめにデータを用意する"
aliases = ["/blog/factorybot-1/"]

+++

Fixturesの管理のしづらさに耐えかねてFactoryBotへ移行しようとしている，とあるRailsプロジェクトがあるのだが，移行に際して懸念していることがテストの低速化だ．
Fixturesならテストの前にレコードを作成しテストでそれを使い回すことになる一方で，FactoryBotの場合は下手するとexampleの数だけINSERT文が走りテストの低速化を招く．
Fixturesのように，FactoryBotを使ってテストの最初にレコードを作成することができればそれを回避することができると考え，仕組みを考えてみた．

<!--more-->

## 想定状況
例えば`User`のようなModelはどのRailsプロジェクトにもあると思う．多くのAssosiationが定義されており，Userのレコードが様々なテストで必要となってくる．
そのような状況において，各exampleでUserレコードをINSERTしていては前述の通りコストがかかる．
このようなよく使うデータに関してはあらかじめDBに用意しておきたい．
(ただしデータは1度しか作成されないため，テストのランダム性は失なわれる．その点はトレードオフになる)

## 設定
`spec/support/initialize_data.rb`というファイルを用意する．内容は以下の通り．

``` ruby
RSpec.shared_context 'initialize data' do
  let(:test_user) { User.find(RSpec.configuration.test_data[:user]) }
end

RSpec.configure do |config|
  config.add_setting :test_data
  config.test_data = {}

  config.before :suite do
    config.test_data[:user] = FactoryBot.create(:user).id
  end

  config.include_context 'initialize data'

  config.after :suite do
    User.destroy_all
  end
end
```

## 解説
### データの作成と削除
RSpecのCallbackを設定できるタイミングは`:suite`，`:all`，`:each`の3つがある[^1]が今回のような「テスト開始前に1度だけ実行する」場合は`before(:suite)`を使用する．  
その中でFactoryBotを使ってレコードを作成する．

ただし`before :suite`はトランザクションの外で行なわれるため，ここで作成したレコードは削除されずにテスト後も残ってしまう．  
テストは毎回クリーンな環境で行いたいため，`after :suite`内で手動でデータを削除する．

### データへのアクセス
example内からここで作成したデータへアクセスするにはひと工夫必要になる．
インスタンス変数は`before :suite`内で定義できない[^2]ため，他の場所でDBから再度取得する必要がある．
この例だと`User.first`のように取得してもよいが，複数のデータを作成する場合は`id`を使うのが安全だ．
idの値を他のスコープへ伝達するために`Custom settings`という機能を使う．[^3]

``` ruby
RSpec.configure do |config|
  config.add_setting :test_data
  config.test_data = {}

  config.before :suite do
    config.test_data[:user] = FactoryBot.create(:user).id
  end
  :
end
```

### データの取得
作成したデータを使わない場合は取得したくないため`let`で取得・定義する．  
テストで共通の`let`を定義するには`shared_context`内に書き，`RSpec.configuration`でそれを`include_context`することになる．

``` ruby
RSpec.shared_context 'initialize data' do
  let(:test_user) { User.find(RSpec.configuration.test_data[:user]) }
end

RSpec.configure do |config|
  :
  config.include_context 'initialize data'
  :
end
```

## 使ってみる
例として以下のようなspecを用意した．このコードだとINSERTが1000回実行される

``` ruby
require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { FactoryBot.create(:user) }

  1000.times do
    it 'behaves like something' do
      expect {
        user.update_attributes(name: 'New Name')
      }.to change(user, :name)
    end
  end
end
```

``` shell
$ time bin/rspec
.......(省略)

Finished in 4.99 seconds (files took 0.5945 seconds to load)
1000 examples, 0 failures

bin/rspec  0.58s user 0.43s system 14% cpu 6.751 total
$ grep -c INSERT log/test.log
1000
```

上の設定を使ってみる．作成したデータへは`test_user`でインスタンスへアクセスできる．
INSERTは1回しか実行されない．

``` shell
$ time bin/rspec
.......(省略)

Finished in 4.29 seconds (files took 0.53682 seconds to load)
1000 examples, 0 failures

bin/rspec  0.56s user 0.43s system 16% cpu 5.936 total
$ grep -c INSERT log/test.log
1
```

まだ短い期間しか運用していないため将来これで問題が起こるかもしれないが，アイデアとして記録を残しておく．

以上．

ここで挙げたコードは↓にある  
[uyorum/play-ruby-on-rails at rspec/initialize-with-factorybot](https://github.com/uyorum/play-ruby-on-rails/tree/rspec/initialize-with-factorybot)

[^1]: [`before` and `after` hooks - Hooks - RSpec Core - RSpec - Relish](https://relishapp.com/rspec/rspec-core/v/3-7/docs/hooks/before-and-after-hooks)
[^2]: WARNING: Setting instance variables are not supported in before(:suite). [`before` and `after` hooks - Hooks - RSpec Core - RSpec - Relish](https://relishapp.com/rspec/rspec-core/v/3-7/docs/hooks/before-and-after-hooks)
[^3]: [custom settings - Configuration - RSpec Core - RSpec - Relish](https://relishapp.com/rspec/rspec-core/v/3-7/docs/configuration/custom-settings)
