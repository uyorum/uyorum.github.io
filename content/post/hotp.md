+++
Categories = []
Tags = []
title = "ワンタイムパスワード生成アルゴリズムについて学ぶ1 - HOTP"
date = "2015-07-24T22:57:11+09:00"
aliases = ["/blog/hotp/"]

+++

今後，OTPを扱うことになりそうなので予習しておく．

<!--more-->

## 概要
* OTP生成のアルゴリズムとして生成回数を変数に用いるHOTPと時刻を変数に用いるTOTPがある．
* 両者はそれぞれ[RFC 4226](https://tools.ietf.org/html/rfc4226)と[RFC 6238](http://tools.ietf.org/html/rfc6238)で規定されている．
* RFCを読みながらOTPについて学んでいく．

### 背景
* ここ最近，インターネット上では単一の静的な文字列(パスワード)による認証では不十分であることがわかってきた．
* 各ベンダーの相互互換性のない実装のせいで，二要素認証はあまり普及してこなかった．
* インターネットへ二要素認証を普及させるには，トークンなどの専用機ではなくより柔軟なデバイス(スマートフォンなどを指していると思われる)で使用できるようにする必要がある
* ワンタイムパスワードは，クライアントマシンに特別なソフトウェアをインストールする必要がないという面で，PKIや生体認証などよりもしばしば推奨される．
    * そのためユーザは様々なデバイスを渡り歩くことができる

### アルゴリズムの要件
MUST, SHOULDなどの単語の意味は[RFC2119](https://tools.ietf.org/html/rfc2119)で定義されている．

1. アルゴリズムはsequence-bacedまたはcounter-basedでなければならない．(MUST)
1. アルゴリズムはその実装において以下の面でハードウェアに対してeconomicalであるべき．(SHOULD)
    * バッテリー
    * ボタン数
    * 計算量
    * ディスプレイサイズ
1. アルゴリズムはいずれの数的な入力をサポートしないハードウェアでも動作しなければならない．(MUST)
1. アルゴリズムの出力は読みやすく入力しやすいものでなければならない．(MUST)   
    また6文字以上の数字で構成されるのが望ましい．

### アルゴリズムの概要
Rubyでの実装例とともに段階的に解説していく．

1. インプットとしてSecret Key(サーバとクライアントで事前に共有しておく文字列)，カウンタ，桁数をとる．

    ```ruby
    secret = '12345678901234567890'
    count = 1
    digit = 6
    ```

1. カウンタは8桁のバイト文字列に変換しておく  
e.g.) `count = 10 => count_in_byte = \x00\x00\x00\x00\x00\x00\x00\x0a`

    ```ruby
    count_in_byte = ''
    for i in (0..7)
      count_in_byte = ((count & 0xff) << (8 * i)).chr + count_in_byte
      count >>= 8
    end
    ```

1. Secret Keyと，変換したカウンタを用いてHMAC-SHA1([RFC 2104](https://tools.ietf.org/html/rfc2104))を計算する

    ```ruby
    hmac = OpenSSL::HMAC.digest('sha1', secret, count_in_byte)
    ```

1. 計算した値(20バイトの文字列)の末尾4ビットをオフセットとする

    ```ruby
    offset = hmac[-1].ord & 0xf
    ```

1. 先ほどのHMAC-SHA1値のoffsetバイト目から4バイトのうち末尾31ビットを取り出して数値に変換する

    ```ruby
    num = (hmac[offset].ord & 0x7f) << 24 |
          (hmac[offset + 1].ord & 0xff) << 16 |
          (hmac[offset + 2].ord & 0xff) << 8 |
          (hmac[offset + 3].ord & 0xff)
    ```

1. 変換後の数値の末尾n桁がHOTPである(ここではdigit=6なので末尾6桁)

    ```ruby
    puts num % (10 ** digit)
    ```

### HOTPを生成してみる
Rubyで実装したプログラムを用いて実際にHOTPを生成してみる．今回は比較対象としてGoogle Authenticatorでも同時にHOTPを生成する．  

まずは両者でSecret Keyを共有する必要がある．Secret Keyは"12345678901234567890"とする．(本来はSecretKeyの生成方法にも気を払うべきである．)  
GoogleAuthenticatorへのSecretKeyの渡し方として以下の2つの方法がある．

> * Key provisioning via scanning a QR code
> * Manual key entry of RFC 3548 base32 key strings

[google/google-authenticator Wiki](https://github.com/google/google-authenticator/wiki) より

今回は簡単のため後者の方法をとる．
先程のSecretKeyをBase32でエンコードする．

```shell
$ irb
irb(main):001:0> require 'base32'
=> true
irb(main):002:0> Base32.encode("12345678901234567890")
=> "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ"
```

できた．これをスマホへ持っていってGoogleAuthenticatorへ入力する．(余談だがPCからスマホへの文字列の引き渡しにはPushbulletが役に立った)
生成した文字列を"キー"へ入力し，"カウンタベース"を選択する．

![01.jpg](/hotp/01.jpg)

1回目のHOTPを生成．

![02.jpg](/hotp/02.jpg)

```shell
$ ruby hotp.rb
287082
```

2回目．

![03.jpg](/hotp/03.jpg)

ソースを編集して`count=2`にしてから実行．

```shell
$ ruby hotp.rb
359152
```

確かに両者で同じ値が出力されている．このようにサーバ側(今回はRubyプログラム)とクライアント側(今回はGoogleAuthenticator)でOTPを生成して一致しているかどうかで認証を行う．

### HOTPを用いた認証の流れ
* セットアップ  
クライアントとサーバでSecret Keyを共有する．  
カウンタを1にセットし，クライアント，サーバそれぞれが保持しておく．

* 認証時
    1. 通常の(パスワード等による)認証の後，クライアント側でHOTPを生成し，サーバへ送信する．  
        その後，クライアント側のカウンタを2にセットする．
    1. サーバ側でもHOTPを生成する．両者が一致した場合は認証成功とみなす．  
        その後，サーバ側のカウンタを2にセットする．  
        一致しなかった場合は認証失敗とみなす．カウンタは1のまま．

### カウンタの再同期
先ほど説明した流れではクライアント側のカウンタがサーバ側より進んでしまうことがある．(クライアント側でHOTPを生成したが認証を行なわなかった場合など)  
その場合に備えて，RFC内ではカウンタの再同期の仕組みを組込むことが推奨されている．

1. あらかじめサーバ側で整数値look-ahead parameter(記号sで表す)を設定しておく．
1. HOTPによる認証を求められた際に，サーバは保持しているカウンタに対するHOTPに加えて次のs個分のHOTPも生成し，クライアント側のHOTPと照合する．
1. もしその中に一致するものがあった場合は認証成功とし，そのHOTPに対応するカウンタ+1をサーバ側カウンタにセットする．

以上のような流れを踏むことで最大sだけカウンタがずれてもカウンタの再同期が可能になる．

![04.jpg](/hotp/04.jpg)

### その他
RFC内ではその他にも以下のような要素について述べられている．が、今回はこれで力尽きたので今度書く．

* 認証試行回数の上限値
* Secret Keyの保存方法
* Secret Keyの生成方法
* サーバとクライアントの双方向認証
* HOTP生成アルゴリズムのセキュリティ強度


図を書くのにはどのソフトがいいんだろう…
