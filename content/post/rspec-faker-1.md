+++
date = "2017-12-28T18:19:55+09:00"
slug = ""
tags = ["",""]
title = "RSpecでFakerを使うならKernel.srandを設定しておけという話"
aliases = ["/blog/rspec-faker-1/"]

+++

RSpecでFaker[^1]を使ってテストデータを用意している場合，テストデータが毎回ランダムになるゆえに，特に工夫をしないとテストを再現させることができなくなる．  
パスしなかったテストを再現できないとトラブルシュートが難しくなってしまうが，それをある程度解決する方法を見つけたのでメモしておく

<!--more-->

## どんな状況か
自分が出会ったのはRailsでFactoryBotとFakerを組み合わせて使っている場合に出会った．
あまりいい例ではないが，以下に具体的な状況を設定する

**models/user.rb**

``` ruby
class User < ApplicationRecord
  validates :name, format: /\A[a-zA-Z0-9 ]+\z/
end
```

**factories/user.rb**

``` ruby
FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
  end
end
```

**spec/models/user_spec.rb**

``` ruby
require 'rails_helper'

RSpec.describe User, type: :model do
  let!(:user) { FactoryBot.create(:user) }

  it "can be destroyed" do
    expect {
      user.destroy
    }.to change(User, :count).by(-1)
  end
end
```

`User`の`name`属性はバリデーションとして正規表現で`/\A[a-zA-Z0-9 ]+\z/`にマッチすることと設定している．  
しかし`Faker::Name.name`は値に「.」を含むことがある．[^2]  
その場合にテスト中の`let!(:user) { FactoryBot.create(:user) }`に失敗し，結果的にテストがパスしないことになる．  
しかもその際に表示されるメッセージは以下のようになり，原因がはっきりと表示されない．

``` shell
$ bin/rspec
F

Failures:

  1) User can destroy
     Failure/Error: let!(:user) { FactoryBot.create(:user) }

     ActiveRecord::RecordInvalid:
       Validation failed: Name is invalid
```

この例ははただの設定ミスであり，原因も単純なので「Fakerの生成した値が悪かったのかな」と推測もできるのだが，そのような状況ばかりではないだろう．

ちなみにRSpecのテストを再現させる方法というと，テストが通らなかったときと同じseed値を指定してRSpecを実行するという方法がある．  
しかしこれはあくまでテストの実行順を再現させるだけであり，その他のランダム化されている箇所は再現できない．当然Fakerの生成する値も再現できない．

## 解決方法
Fakerはその値の生成に`Random.rand`や`Kernel.rand`を使っているようなのでそのシード値を与えてやればよい．
この方法はRSpecのドキュメントでも提案されており[^3]，デフォルトの`spec_helper.rb`にもコメントアウトされた状態で書かれている．[^4]

**spec/spec_helper.rb**

``` ruby
RSpec.configure do |config|
  :
  Kernel.srand config.seed
  :
end
```

`Kernel.srand`に整数値を渡すことで`Kernel.rand`や`Random.rand`のシード値を設定することができる[^5]

## 試してみる
実際にこの設定の動作を確認してみるために以下のようなテストコードを用意する．

**spec/random_data_spec.rb**

``` ruby
require 'rails_helper'

RSpec.describe 'Randomized data' do
  it 'prints some random strings' do
    5.times { puts Faker::Name.name }
  end
end
```

`Faker::Name.name`を実行し値を出力する
まずは上記設定を行なっていない状態でRSpecのseedを指定して実行する

``` shell
$ bin/rspec spec/random_data_spec.rb --seed 1234

Randomized with seed 1234
Jackson Erdman DVM
Miss Angelina Nolan
Nicholaus Walker PhD
Terrence Pacocha
Camren Denesik
.

Finished in 0.54782 seconds (files took 0.50447 seconds to load)
1 example, 0 failures

Randomized with seed 1234

$ bin/rspec spec/random_data_spec.rb --seed 1234

Randomized with seed 1234
Kirsten Ondricka
Thora Jenkins
Lenny Mertz MD
John Sauer
Liliana Heathcote
.

Finished in 0.53317 seconds (files took 0.50113 seconds to load)
1 example, 0 failures

Randomized with seed 1234
```

当然Fakerは毎回異なる値を生成する．

それでは上記設定を行なった状態で同じように実行してみる．

``` shell
$ bin/rspec spec/random_data_spec.rb --seed 1234

Randomized with seed 1234
Ian Bruen
Dallas Gutkowski
Augusta Kulas DVM
Glen Kuphal
Jamarcus Watsica
.

Finished in 0.61383 seconds (files took 0.59588 seconds to load)
1 example, 0 failures

Randomized with seed 1234

$ bin/rspec spec/random_data_spec.rb --seed 1234

Randomized with seed 1234
Ian Bruen
Dallas Gutkowski
Augusta Kulas DVM
Glen Kuphal
Jamarcus Watsica
.

Finished in 0.57579 seconds (files took 0.52938 seconds to load)
1 example, 0 failures

Randomized with seed 1234
```

Fakerは同じ値を生成するようになった．
この状態でCIを行い，テストが通らなかったらそのときのseed値を指定すれば手元でも(Fakerや`rand`を使った値に関しては)再現できるようになる．

以上．

なお，ここで挙げたコードはGitHubに上げてある．  
[uyorum/play-ruby-on-rails](https://github.com/uyorum/play-ruby-on-rails/tree/rspec/faker-srand)

[^1]: [GitHub - stympy/faker: A library for generating fake data such as names, addresses, and phone numbers.](https://github.com/stympy/faker)
[^2]: [faker/name.md at master · stympy/faker](https://github.com/stympy/faker/blob/master/doc/name.md)
[^3]: [Randomization can be reproduced across test runs - Command line - RSpec Core - RSpec - Relish](https://relishapp.com/rspec/rspec-core/docs/command-line/randomization-can-be-reproduced-across-test-runs)
[^4]: [rspec-core/spec_helper.rb at v3.7.0 · rspec/rspec-core](https://github.com/rspec/rspec-core/blob/v3.7.0/lib/rspec/core/project_initializer/spec/spec_helper.rb)
[^5]: [module Kernel (Ruby 2.4.0)](https://docs.ruby-lang.org/ja/latest/class/Kernel.html\#M_SRAND)
