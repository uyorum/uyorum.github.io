+++
date = "2019-06-04T22:38:40+09:00"
slug = ""
tags = ["",""]
title = "バッファローのイーサネットコンバータでトラブった話"
aliases = ["/blog/buffalo-ethernet-converter/"]

+++

## まとめ

* Buffaloの無線ルータWEX-G300をイーサネットコンバータとして使っていた
* この機器が上流(WiFi親機)へのパケットを転送するときに，パケットの送信元MACを自分のMACに変えてしまう
* ペイロードにMACアドレスが含まれるような通信ではこれが原因で問題が発生しうる

<!-- more -->

## 構成

* 下図のようにWiFiルータ(AP)にBuffaloのWEX-G300を接続，さらに有線ポートにPC(以下，Host A)を接続している．
* 同じWiFiルータに無線LANを内蔵したPC(以下，Host B)を接続している．
* Host AとHost Bは同一のL2ネットワークに属している．

![network.jpg](/buffalo-ethernet-converter/network.jpg)

## Pingで確認

Host A → Host B へPingを打ってみる．

### Host Aでパケットキャプチャ

``` shell
$ sudo tcpdump -i eno1 -n -e icmp
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eno1, link-type EN10MB (Ethernet), capture size 262144 bytes
21:43:06.274393 ec:a8:6b:f9:7a:60 > 28:cf:da:02:a5:40, ethertype IPv4 (0x0800), length 98: 10.0.0.3 > 10.0.0.153: ICMP echo request, id 1749, seq 1, length 64
21:43:06.276067 28:cf:da:02:a5:40 > ec:a8:6b:f9:7a:60, ethertype IPv4 (0x0800), length 98: 10.0.0.153 > 10.0.0.3: ICMP echo reply, id 1749, seq 1, length 64
```

### Host Bでパケットキャプチャ

``` shell
$ sudo tcpdump -i en1 -n -e icmp
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on en1, link-type EN10MB (Ethernet), capture size 262144 bytes
21:43:06.299805 34:3d:c4:ee:aa:61 > 28:cf:da:02:a5:40, ethertype IPv4 (0x0800), length 98: 10.0.0.3 > 10.0.0.153: ICMP echo request, id 1749, seq 1, length 64
21:43:06.299877 28:cf:da:02:a5:40 > 34:3d:c4:ee:aa:61, ethertype IPv4 (0x0800), length 98: 10.0.0.153 > 10.0.0.3: ICMP echo reply, id 1749, seq 1, length 64
```

ICMP echo requestの送信元MACが異なる値となっている．
元のパケットの送信元MAC(`ec:a8:6b:f9:7a:60`)はHost AのNICのMACアドレスなのだが，Host Bが受け取ったパケットの送信元MAC(`34:3d:c4:ee:aa:61`)はWEX-G300のMACアドレスである．(WEX-G300のMACアドレスはWeb UIから確認できる)

またICMP echo replyの宛先MACも異なる値となっている．おそらくWEX-G300自身が内部でIPアドレスとMACアドレスの対応表(またはARPテーブル)を持っており，その対応表をもとに正しいMACアドレスと考えられる．

ほとんどの通信ではこの仕様でも問題は発生しないだろうが，ペイロードにMACアドレスが含まれるような通信では問題となりうる．
自分の環境では，DHCP[^1]で払い出したはずのIPアドレスを別のMACアドレスが使っている(ARPスプーフィング)と誤検知し，ルータでパケットをドロップするという事象が発生した．

以上

[^1]: DHCPではEthernetヘッダではなくUDP上のDHCPペイロード内に含まれるMACアドレスを使用しており，かつWEX-G300ではここの書き換えには対応していないからだと考えられる
