+++
slug = ""
tags = ["FortiGate"]
title = "複数インターネット回線を持つFortiGateはRPF機能に注意"
date = "2022-10-06T00:02:27+09:00"
+++

FortiGateはデフォルトでRPF（Reverse Path Forwading）という機能が有効になっている（この機能はAnti-Spoofingとも呼ばれることがある）。  
FortiGateに複数のインターネット回線（アップリンク）が接続されており、それぞれの回線（グローバルアドレス）でインターネットからのアクセスを受けている場合、
このRPF機能を考慮してルーティングを設定する必要がある。

<!--more-->

## 構成図

どんな構成か簡単に説明しておく（かなり簡略化している）。

![diagram.svg](/fortigate-rpf/diagram.svg)

* FortiGateに2つのインターネット回線を接続している（以下、ISP AとISP Bとする）
* ISP Aからはグローバルアドレス1.1.2.0/24、ISP Bからは1.2.2.0/24が払い出されている
* それぞれのグローバルアドレス宛のパケットは上位のルータからそれぞれ1.1.1.2（ISP A）と1.2.1.2（ISP B）にルーティングされてくる
* 1.1.2.1と1.2.2.1でサーバを構築、それぞれインターネットからのアクセスを受け付けている
* 各サーバからインターネットへ通信するとき、送信元アドレスに応じてネクストホップを使い分ける
    * 以下のスタティックルートを設定
        * 宛先：0.0.0.0/0
        * 出力インターフェース：wan1
        * ネクストホップ：1.1.1.1
    * 以下のポリシールートを設定
        * 送信元：1.2.2.0/24
        * 宛先：0.0.0.0/0
        * 出力インターフェース：wan2
        * ネクストホップ：1.2.1.1

## 事象

上記のような構成とコンフィグで構築し、インターネットからのアクセスを受け付けようとしたところ、
インターネットから1.1.2.1へのアクセスはうまくいくが、1.2.2.1へのアクセスがうまく通らなかった。
調べたところFortiGateへパケットは届いているが、1.2.2.1へパケットを送出していなかった。

![diagram-2.svg](/fortigate-rpf/diagram-2.svg)

FortiGateのトラフィックログにもドロップしたことは一切出力されておらず、ひと目では原因がわからなかった。

## 回避方法

いろいろと調べたところ、FortiGateはデフォルトでRPF（Anti-Spoofing）という機能が有効になっており、
この機能に引っかかった通信はFortiGateによってドロップされるうえ、ログには出力されないらしい。

FortiGateがパケットを受信したとき、自身のスタティックルートを走査する。
パケットを受信したインターフェースのスタティックルートのうち、宛先アドレスがパケットの送信元アドレスを含んでいるルーティングがある場合
FortiGateはパケットを処理し、ない場合はドロップする。[^1]

RPF機能を無効にすれば回避できるそうだがデフォルトで有効となっているセキュリティ関連の機能のため、念のため無効にはせず別の方法で回避する。

今回の構成では0.0.0.0/0宛で送信元インターフェースがwan2のスタティックルートを追加すればよいが、
そうすると配下のサーバからのパケットがwan2の方へルーティングされてしまう。（実際にはECMP扱いでロードバランシングされる）
1.1.2.1からの通信は固定でwan1へルーティングしたいため、優先順位のようなものを設定したくなる。

FortiGateにはそのような（似た）項目が2つある。ディスタンスとプライオリティ。
結論を言うと、RPF回避のために追加するスタティックルートはプライオリティに大きい値を設定してやればよい。
ディスタンスの方も同様に優先順位を設定する項目だが、一方のインターフェースがダウンしない限り優先度が低い方のルートはルートとして出てこない。
この状態だとRPFの回避はできないため、プライオリティという項目を使う必要がある。

|宛先|出力インターフェース|ネクストホップ|プライオリティ|
|:--|:--|:--|:--|
|0.0.0.0/0|wan1|1.1.1.1|1|
|0.0.0.0/0|wan2|1.2.1.1|2|

詳細は以下のページを参照。  
[Technical Note: Routing behavior depending on distance and priority for static routes, and Policy Based Routes - Fortinet Community](https://community.fortinet.com/t5/FortiGate/Technical-Note-Routing-behavior-depending-on-distance-and/ta-p/198221)

## 参考

* [Technical Note: Details about FortiOS RPF (Reverse Path Forwarding), also called Anti-Spoofing - Fortinet Community](https://community.fortinet.com/t5/FortiGate/Technical-Note-Details-about-FortiOS-RPF-Reverse-Path-Forwarding/ta-p/190100)
* [Technical Note : Reverse Path Forwarding (RPF) implementation and use of strict-src-check enable|disable - Fortinet Community](https://community.fortinet.com/t5/FortiGate/Technical-Note-Reverse-Path-Forwarding-RPF-implementation-and/ta-p/194382)
* [Technical Note: Routing behavior depending on distance and priority for static routes, and Policy Based Routes - Fortinet Community](https://community.fortinet.com/t5/FortiGate/Technical-Note-Routing-behavior-depending-on-distance-and/ta-p/198221)
* [Technical Tip: How to disable Reverse Path Forwarding (RPF) per interface - Fortinet Community](https://community.fortinet.com/t5/FortiGate/189518?externalID=10376)

[^1]: デフォルトのFeasible Path Reverse Path Forwarding：[Technical Note : Reverse Path Forwarding (RPF) implementation and use of strict-src-check enable|disable - Fortinet Community](https://community.fortinet.com/t5/FortiGate/Technical-Note-Reverse-Path-Forwarding-RPF-implementation-and/ta-p/194382)  
