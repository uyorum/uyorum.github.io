+++
slug = ""
tags = ["epgstation", "docker", "raspberrypi", "ffmpeg"]
title = "RaspberryPi上のEPGStationコンテナ用にffmpegをビルドする（2023年9月版）"
date = "2023-09-24T00:34:11+09:00"
+++

[以前](../raspberrypi-mirakurun-epgstation/)、RaspberryPi上にEPGStationをDockerを使ってセットアップしました。
この中でRaspberryPiのハードウェアエンコードが有効なffmpegをビルドしたのですが、
今回軽い気持ちでEPGStationコンテナを最新化しようとしたところこのffmpegのビルドがエラー連発で大苦戦してしまいました。
Dockerfileは変えていなかったので外部の要因によるもののようです。

<!--more-->

## `error: invalid 'asm': invalid operand for code 'w'`

まずはビルド中にこのエラー。

``` shell
In file included from ./libavutil/bswap.h:38,
                 from ./libavutil/intreadwrite.h:25,
                 from libavfilter/vf_curves.c:25:
In function 'av_bswap16',
    inlined from 'parse_psfile' at libavfilter/vf_curves.c:381:5:
./libavutil/aarch64/bswap.h:31:5: error: invalid 'asm': invalid operand for code 'w'
   31 |     __asm__("rev16 %w0, %w0" : "+r"(x));
      |     ^~~~~~~
./libavutil/aarch64/bswap.h:31:5: error: invalid 'asm': invalid operand for code 'w'
In function 'av_bswap16',
    inlined from 'parse_psfile' at libavfilter/vf_curves.c:385:9:
./libavutil/aarch64/bswap.h:31:5: error: invalid 'asm': invalid operand for code 'w'
   31 |     __asm__("rev16 %w0, %w0" : "+r"(x));
      |     ^~~~~~~
./libavutil/aarch64/bswap.h:31:5: error: invalid 'asm': invalid operand for code 'w'
In function 'av_bswap16',
    inlined from 'parse_psfile' at libavfilter/vf_curves.c:388:13:
./libavutil/aarch64/bswap.h:31:5: error: invalid 'asm': invalid operand for code 'w'
   31 |     __asm__("rev16 %w0, %w0" : "+r"(x));
      |     ^~~~~~~
./libavutil/aarch64/bswap.h:31:5: error: invalid 'asm': invalid operand for code 'w'
In function 'av_bswap16',
    inlined from 'parse_psfile' at libavfilter/vf_curves.c:389:13:
./libavutil/aarch64/bswap.h:31:5: error: invalid 'asm': invalid operand for code 'w'
   31 |     __asm__("rev16 %w0, %w0" : "+r"(x));
      |     ^~~~~~~
./libavutil/aarch64/bswap.h:31:5: error: invalid 'asm': invalid operand for code 'w'
CC      libavfilter/vf_deband.o
make: *** [ffbuild/common.mak:67: libavfilter/vf_curves.o] Error 1
make: *** Waiting for unfinished jobs....
```

RaspberryPi OSは32bit版のはずなのに`aarch64`の文字列が見えるのが気になる。

``` shell
$ uname -m
aarch64
$ cat /etc/os-release
PRETTY_NAME="Raspbian GNU/Linux 11 (bullseye)"
NAME="Raspbian GNU/Linux"
VERSION_ID="11"
VERSION="11 (bullseye)"
VERSION_CODENAME=bullseye
ID=raspbian
ID_LIKE=debian
HOME_URL="http://www.raspbian.org/"
SUPPORT_URL="http://www.raspbian.org/RaspbianForums"
BUG_REPORT_URL="http://www.raspbian.org/RaspbianBugs"
$ uname -m
aarch64
$ getconf LONG_BIT
32
$ dpkg --print-architecture
armhf
```

カーネルは64bit、ユーザーランドは32bitになっている。
コンテナ内も同様。

``` shell
# cat /etc/os-release
PRETTY_NAME="Debian GNU/Linux 12 (bookworm)"
NAME="Debian GNU/Linux"
VERSION_ID="12"
VERSION="12 (bookworm)"
VERSION_CODENAME=bookworm
ID=debian
HOME_URL="https://www.debian.org/"
SUPPORT_URL="https://www.debian.org/support"
BUG_REPORT_URL="https://bugs.debian.org/"
# getconf LONG_BIT
32
# dpkg --print-architecture
armhf
```

で見つけたのがこの記事。
[RasPi OS 32bitをインストールしたのにaarch64??](https://zenn.dev/matsujirushi/scraps/53a08cb853ea0e)

どうやら今年のどこかにデフォルト動作が変わり、デフォルトで64bitカーネルで起動するようになったようです。
`/boot/config.txt`で動作を変更できるので32bitカーネルで起動するように変更。

[Raspberry Pi Documentation - The config.txt file](https://www.raspberrypi.com/documentation/computers/config_txt.html#arm_64bit)

設定ファイルを変更したら再起動。アーキテクチャがarmv7lになっていることを確認します。

``` shell
$ uname -m
armv7l
```

これで上のエラーは回避できます。

## `docker compose build`だとコケる

その後もなぜかdocker compose buildだとエラーになります。

``` shell
gcc is unable to create an executable file.
If gcc is a cross-compiler, use the --enable-cross-compile option.
Only do this if you know what cross compiling means.
C compiler test failed.

If you think configure made a mistake, make sure you are using the latest
version from Git.  If the latest version fails, report the problem to the
ffmpeg-user@ffmpeg.org mailing list or IRC #ffmpeg on irc.libera.chat.
Include the log file "ffbuild/config.log" produced by configure as this will help
solve the problem.
```

`docker run`でコンテナを上げて手動でコマンドを実行していくとエラーにはならない。
しかも`docker build`でもエラーにならず、ビルドは成功した。

いろいろと試行錯誤した結果、あらかじめ`docker pull l3tnun/epgstation:master-debian`でローカルのイメージを最新化しておくとでなくなったように見えます。
そもそも`docker compose build --pull`でビルドしていたのにイメージをPullしていなかった模様。原因は不明。

コンテナ化してもなかなか再現性を維持するのは難しい…。

{{< affiliate asin="B081YD3VL5" title="【国内正規代理店品】Raspberry Pi4 ModelB 4GB ラズベリーパイ4 技適対応品【RS・OKdo版】 " >}}
