+++
slug = ""
tags = ["epgstation", "ffmpeg"]
title = "EPGStationでときどきエンコードに失敗する"
date = "2023-09-30T21:58:49+09:00"
+++

EPGStationで録画した番組は自動でmp4にエンコードするようにしています。
しかしいくつかの番組でmp4のファイルサイズが0バイトになっておりエンコードに失敗しているようです。
しかも既存のスクリプトではこの状況をエンコード失敗として検知できないらしく、エンコードが完了したとしてソースのtsファイルを削除してしまうのでリカバリできず痛手となっていました。

ひとまずはエンコード完了後のtsファイル削除をしない設定にしていましたがきちんと対処します。

<!--more-->

対処内容は以下の2つです。

* 正常にエンコードできるようにする
* 出力ファイルサイズが異様に小さい場合は失敗扱いにするようにする  
    こうすることで、万が一別の要因で今回と同じような状況になっても、EPGStationがエンコード失敗を検知してtsファイルの削除をしないはず（未確認）

## 正常にエンコードできるようにする

原因と対処方法はこちらのIssueが非常に参考になりました。

[エンコードに失敗する場合がある · Issue #583 · l3tnun/EPGStation](https://github.com/l3tnun/EPGStation/issues/583)

どうやら前の番組のストリーム情報が残ってしまい、存在しないはずのストリームが存在するとffmpegが誤検知するためにエンコードに失敗することがあるようです。

試しに手元にある問題のtsファイルのストリーム情報を確認してみます。確認には`ffprobe`というコマンドが使えるようです。

``` shell
$ ffprobe problem.m2ts
...
Stream #0:0[0x100]: Video: mpeg2video (Main) ([2][0][0][0] / 0x0002), yuv420p(tv, t709, top first), 1440x1080 [SAR 4:3 DAR 16:9], 29.97 fps, 29.97 tbr, 90k tbn, 59.94 bc
  Side data:
    cpb: bitrate max/min/avg: 20000000/0/0 buffer size: 9781248 vbv_delay: N/A
Stream #0:1[0x110]: Audio: aac (LC) ([15][0][0][0] / 0x000F), 48000 Hz, stereo, fltp, 55 kb/s
Stream #0:2[0x130]: Subtitle: arib_caption (Profile A) ([6][0][0][0] / 0x0006)
Stream #0:3[0x138]: Data: bin_data ([6][0][0][0] / 0x0006)
Stream #0:4[0x140]: Unknown: none ([13][0][0][0] / 0x000D)
Stream #0:5[0x160]: Unknown: none ([13][0][0][0] / 0x000D)
Stream #0:6[0x161]: Unknown: none ([13][0][0][0] / 0x000D)
Stream #0:7[0x162]: Unknown: none ([13][0][0][0] / 0x000D)
Stream #0:8[0x163]: Unknown: none ([13][0][0][0] / 0x000D)
Stream #0:9[0x164]: Unknown: none ([13][0][0][0] / 0x000D)
Stream #0:10[0x165]: Unknown: none ([13][0][0][0] / 0x000D)
Stream #0:11[0x111]: Audio: aac ([15][0][0][0] / 0x000F), 0 channels...
```

0:11ストリームがおかしいです。オーディオストリームのようですが0 channelsとなっています。
上のIssueと同じ事象のようですが、ストリーム番号が異なります。

他のいくつかのtsファイルを見てみましたがストリーム10以降にオーディオが入ることはなさそうなので
いっそ10以降のストリームにオーディオストリームがあっても無視するようにします。

`enc.js`を修正します。

``` diff
@@ -52,12 +53,16 @@ if (isDualMono) {
     ]);
 } else {
     Array.prototype.push.apply(args, ['-map', '0:a']);
+    // 不要なストリームを削除
+    for (let s of [10, 11, 12, 13]) {
+        Array.prototype.push.apply(args, ['-map', `-0:${s}?`]);
+    };
 }
```

`-map`は出力ファイルに含めるストリームを選択するオプションですが、ストリーム番号の頭に`-`をつけることで、それより前のオプションで選択されていてもそのストリームは除外するようになります。

[Map – FFmpeg](https://trac.ffmpeg.org/wiki/Map#Modifiers)

これによる副作用は不明ですがひとまずこれで問題のtsもエンコードできるようになりました。

## 出力ファイルサイズが小さい場合は失敗扱いにする

上で貼ったIssueでも提案されていますが、エンコード時の適切なオプションは入力ファイルのストリームによって調整すべきなので上の修正でも場合によっては失敗する可能性があります。
そのためエンコード終了時に出力ファイルサイズが極端に小さい場合はエンコード失敗となるよう`enc.js`を修正します。

``` diff
@@ -1,3 +1,4 @@
+const fs = require('fs');
 const spawn = require('child_process').spawn;
 const execFile = require('child_process').execFile;
 const ffmpeg = process.env.FFMPEG;
@@ -163,6 +168,15 @@ Array.prototype.push.apply(args, [output]);
         throw new Error(err);
     });

+    // 出力ファイルのサイズが10KBより小さい場合は失敗とみなす
+    child.on('exit', (code) => {
+        var stat = fs.statSync(output);
+        if (stat.size < 10 * 1024) {
+            console.error(`File size ${stat.size} bytes is too small (< 10k). Raising error`);
+            throw new Error(1);
+        }
+    });
+
     process.on('SIGINT', () => {
         child.kill('SIGINT');
     });
```

これで今回のように出力ファイルが0バイトになった場合は失敗扱いになるようになります。

以上
