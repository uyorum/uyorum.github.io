+++
Categories = []
Tags = []
title = "ffmpeg(avconv)でmp3からブランクスクリーン(黒)のmp4を作成する"
date = "2015-10-15T21:15:02+09:00"

+++

逆(mp4からmp3を抽出する)はよく見つかるけど日本語の情報がなかったのでまとめておく．

<!--more-->

## 参考
* [Libav documentation : avconv](https://libav.org/avconv.html)
* [[FFmpeg-user] convert mp3 to 3gp or MP4](http://ffmpeg.org/pipermail/ffmpeg-user/2013-June/015632.html)
* [ffmpeg: 1 image + 1 audio file = 1 video - Stack Overflow](http://stackoverflow.com/questions/5887311/ffmpeg-1-image-1-audio-file-1-video)

## コマンド
ffmpegやavconvを初めて自分で使ったのでまとめておく．  
自分はavconvを使ったがたぶんffmpegも同じなんじゃないかな(適当)  
オプション一覧はあるがその意味が説明されているドキュメントを見つけられなかったのでオプションの意味が間違ってるかもしれない．

標題を達成するには...

```shell
$ avconv -y -s 320x240 -f rawvideo -pix_fmt rgb24 -r 1 -i /dev/zero -i /path/to/mp3 -vcodec libx264 -acodec copy -shortest /name/of/output.mp4
```

### 各オプションの解説

* `-y`  
同名のファイルが既にあった場合でも確認なしでファイルを上書きする

* `-s 320x240`  
-s[:stream_specifier] size (input/output,per-stream)  
映像のサイズ．今回は真っ黒の画面にするのでサイズはどうでもいい．小さめでキリのよいQVGAにする．

* `-f rawvideo`  
`-f fmt (input/output)`  
入力または出力のフォーマットを(強制的に)指定する．  
「強制的」と書いたのは，avconvは入力に指定したファイルの中身や出力に指定したファイルの拡張子からフォーマットを自動で判別するようになっているため．  
→fmtの選択肢は？？

* `-pix_fmt rgb24`  
`-pix_fmt[:stream_specifier] format (input/output,per-stream)`  
pixel formatを指定する．(おそらく)RGBで表現し，1ドットあたり24bit消費する  
`avconv -pix_fmts`で選択肢が表示される．リストを見た感じ，monobの方がサイズが小さくなりそうだったが比較したらrgb24の方が小さくなった(約30分で16byte)．なぜだ．

* `-r 1`  
`-r[:stream_specifier] fps (input/output,per-stream)`  
映像のFPSを指定する．小さい値を指定した方が出来上がりのファイルサイズも小さくなる．ということで1を指定．  

* `-i /dev/zero -i /path/to/mp3`  
inputを指定する．映像とか音声とか自動で判別してくれる模様．便利．  

* `-vcodec libx264`
* `-acodec copy`  
それぞれ`-codec:v`と`-codec:a`へのalias．  
`-codec[:stream_specifier] codec (input/output,per-stream)`  
入力(-iの前に書いた場合)や出力(出力ファイル名の前に書いた場合)のcodecを指定する．(前述の通り，入力のcodecは自動で判別してくれる)  
ここでは出力．映像はX264，音声はcopyを指定することで再エンコードせずにそのまま使用する．

* `-shortest`  
入力に指定したストリームのうち，最も短いものの末尾に到達した時点でエンコードを終了する．  
今回は映像の入力に/dev/zeroを指定しているので(つまり永遠)，このオプションを与えないとエンコードが終了しない．

* `/name/of/output.mp4`  
出力ファイル名．前述の通り.mp4にすればで自動的にMP4形式で出力してくれる．

以上．
