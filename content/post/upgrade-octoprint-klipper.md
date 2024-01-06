+++
slug = ""
tags = ["ガジェット", "3Dプリンタ"]
title = "OctoprintとKlipper環境をアップグレードする"
date = "2024-01-07T01:15:19+09:00"
+++

[前回](../ender-3-pro-customize/)まとめた構成の3Dプリンタの各種ソフトウェアをアップグレードしていきます。

<!--more-->

# 大方針

私の環境ではOctoPiイメージを使って構築しています。  
最新版の[OctoPi 1.0.0](https://octoprint.org/blog/2023/02/22/octopi-release-1-0-0/)ではDebian 11(Bullseye)ベースのRaspberry Pi OSが採用されていますが、それより古いOctoPiはバージョンはDebian 10(Buster)が採用されています。  
今のところRaspberry Pi OSでBusterからBullseyeにアップグレードする方法は公式では存在しないようです（Debianのお作法に従えばできはすると思いますが）。そのためOctoPi 1.0.0にするにはイメージを焼き直して再構築する必要があります。  
今回はその手順は省略し、Busterの中で最新までアップグレードすることにします。  
（OctoPrintやKlipperは最新版もBusterで問題なく動作するようなので最新版にできないのはOSのみです）

# 手順
## バックアップ

念のためバックアップを取っておきます。  
OctoPrintのバックアップはWeb UIから可能です。  
printer.cfgも外部にコピーしておきます。

## OS

``` shell
$ sudo rpi-update
$ sudo reboot
$ sudo apt update
$ sudo apt upgrade
$ sudo reboot
```

## OctoPrint

OctoPrintインストール当時はPython 2製でしたが、現在は[Python 3でしか動かないようです](https://octoprint.org/blog/2022/01/31/octoprint-1.8.0-will-require-python-3/)。  
そのため、、Python 3の実行環境を用意する必要がありますが、幸いなことにセットアップ用のスクリプトが用意されています。（最新版のOctoPiを焼き直せばそれで済む話ですが、前述の通り今回はそれを見送ります）

[cp2004/Octoprint-Upgrade-To-Py3: A script to move an existing OctoPrint install from Python 2 to Python 3](https://github.com/cp2004/OctoPrint-Upgrade-To-Py3)

ただしこのスクリプトを使えるのはOctoPi 0.17以上のみです。それ未満の場合は素直にOctoPiを焼き直すのがいいでしょう。

```shell
$ cd oprint
$ curl -L https://get.octoprint.org/py3/upgrade.py --output upgrade.py
$ python3 upgrade.py
OctoPrint Upgrade to Py 3 (v2.2.2)

This script will move your existing OctoPrint configuration from Python 2 to Python 3
This script requires an internet connection and it will disrupt any ongoing print jobs.

It will install the latest version of OctoPrint and all plugins.
No configuration or other files will be overwritten

Press [enter] to continue or ctrl-c to quit

Checking system info...
Detected OctoPi version 0.17.0
Found version: Python 2.7.16
Checking OctoPrint version...
OctoPrint version: 1.5.3
Reading installed plugins...
No plugins found
If you think this is an error, please ask for help. Note this doesn't include bundled plugins.
Press [enter] to continue or ctrl-c to quit

Updating package list...
[sudo] password for pi:
Checking package list for python3-dev
Installing python3-dev...
Use 'sudo apt autoremove' to remove them.
Successfully installed python3-dev
Checking package list for python3-venv
Installing python3-venv...
Use 'sudo apt autoremove' to remove them.
Successfully installed python3-venv
Creating new Python 3 environment...
Successfully created Python 3 environment at /home/pi/oprint
Installing build dependencies...
  Cache entry deserialization failed, entry ignored
  Cache entry deserialization failed, entry ignored
Updating pip...
Cache entry deserialization failed, entry ignored
Cache entry deserialization failed, entry ignored

Installing OctoPrint... (This may take a while - Do not cancel!)
Collecting required packages
WARNING: Retrying (Retry(total=4, connect=None, read=None, redirect=None, status=None)) after connection broken by 'ProtocolError('Connection aborted.', RemoteDisconnected('Remote end closed connection without response'))': /simple/cachelib/
Installing collected packages
Collecting required packages
Installing collected packages
Collecting required packages
Installing collected packages
OctoPrint successfully installed!

Cleaning up...
Finished! OctoPrint should be ready to go
Once you have verified the install works, you can safely remove the folder /home/pi/oprint.bak
If you want to go back (If it doesn't work) to Python 2 download the file at:
https://raw.githubusercontent.com/cp2004/Octoprint-Upgrade-To-Py3/master/go_back.py

$ sudo reboot
$ sudo apt autoremove
```

再起動後にOctoPrintのWebUIにアクセスすると以下のエラーが表示されていましたが `octoprint` サービスを再起動すると表示されなくなりました。  
（videoグループにはすでに追加されていました）

> OctoPrint cannot check for throttling situations reported by your Pi. vcgencmd doesn't work as expected. Make sure the system user OctoPrint is running under is a member of the "video" group.

## Klipper

続いてKlipperも上げていきます。手順は公式ページに従って進めていきます。

[Frequently Asked Questions - Klipper documentation](https://www.klipper3d.org/FAQ.html?h=update#how-do-i-upgrade-to-the-latest-software)  
[SDCard updates - Klipper documentation](https://www.klipper3d.org/SDCard_Updates.html)

``` shell
$ cd klipper
$ git pull
$ scripts/install-octopi.sh
$ sudo systemctl stop klipper 
$ make menuconfig
$ make clean
$ make
```

続いてファームウェアをボードに焼いていきます。スクリプトが用意されているようなのでそれを使います。

``` shell
$ ./scripts/flash-sdcard.sh /dev/ttyAMA0 btt-skr-v1.3
Flashing /home/pi/klipper/out/klipper.bin to /dev/ttyAMA0
Checking FatFS CFFI Build...
Building FatFS shared library...Done
Connecting to MCU...Connected
Checking Current MCU Configuration...Trying fallback...Done
MCU needs restart: is_config=1, is_shutdown=1
Attempting MCU Reset...Done
Waiting for device to reconnect...Done
Connecting to MCU...Connected
Trying fallback...Initializing SD Card and Mounting file system...

SD Card Information:
Version: 2.0
SDHC/SDXC: False
Write Protected: False
Sectors: 245760
manufacturer_id: 0
oem_id: 0
product_name: APPSD
product_revision: 0.0
serial_number: 00000057
manufacturing_date: 12/2019
capacity: 120.0 MiB
fs_type: FAT16
volume_label: 
volume_serial: 2826674516
Uploading Klipper Firmware to SD Card...Done
Validating Upload...Done
Firmware Upload Complete: firmware.bin, Size: 27656, Checksum (SHA1): 73FCDF5209F2DC55E8A110880C93F6EE87E27E55
Attempting MCU Reset...Done
Waiting for device to reconnect...Done
Connecting to MCU...............................................................................................

SD Card Flash Error: Unable to connect to MCU
Traceback (most recent call last):
  File "/home/pi/klipper/scripts/spi_flash/spi_flash.py", line 1647, in main
    spiflash.run()
  File "/home/pi/klipper/scripts/spi_flash/spi_flash.py", line 1589, in run
    self.run_reactor_task(self.run_verify)
  File "/home/pi/klipper/scripts/spi_flash/spi_flash.py", line 1570, in run_reactor_task
    k_reactor.run()
  File "/home/pi/klipper/klippy/reactor.py", line 292, in run
    g_next.switch()
  File "/home/pi/klipper/klippy/reactor.py", line 340, in _dispatch_loop
    timeout = self._check_timers(eventtime, busy)
  File "/home/pi/klipper/klippy/reactor.py", line 158, in _check_timers
    t.waketime = waketime = t.callback(eventtime)
  File "/home/pi/klipper/klippy/reactor.py", line 48, in invoke
    res = self.callback(eventtime)
  File "/home/pi/klipper/scripts/spi_flash/spi_flash.py", line 1556, in run_verify
    self.mcu_conn.connect()
  File "/home/pi/klipper/scripts/spi_flash/spi_flash.py", line 1202, in connect
    raise SPIFlashError("Unable to connect to MCU")
SPIFlashError: Unable to connect to MCU
```

失敗しました。ファームウェアを焼いてボードを再起動するところまではうまくいっていましたが、再起動後にボードに接続できなくなったようです。
OctoPrintからも接続できません。

``` shell
Send: STATUS
Recv: // mcu 'mcu': Unable to connect
Recv: // Once the underlying issue is corrected, use the
Recv: // "FIRMWARE_RESTART" command to reset the firmware, reload the
Recv: // config, and restart the host software.
Recv: // Error configuring printer
Recv: // Klipper state: Not ready
Recv: !! mcu 'mcu': Unable to connect
```

現在は配線をシンプルにするためRaspberry PiとSKRはUSBではなくGPIOポートを使ってシリアル接続しています。
いろいろと調べたところ`make menuconfig`で通信方法がUSBになっていることを発見したのでシリアルへ変更してビルドし直しました。
（今までなぜ接続できていたのか不明）

``` shell
$ make menuconfig
$ make
```

ボードには接続できないのでSKRのSDカードの直下に `firmware.bin` というファイル名でコピーして電源を入れ直します。
念のためRaspberry Piも再起動するとうまく接続できたようです。

``` shell
Send: STATUS
Recv: // Klipper state: Ready
Send: M115
Recv: ok FIRMWARE_VERSION:v0.12.0-60-g0665dc89 FIRMWARE_NAME:Klipper
```

バージョン番号の末尾文字列はGitのハッシュ値のようです。ひとまずこれで最新版まで上がったことを確認できました。

``` shell
$ git log
commit 0665dc89766bd85c095f18ba84028dc47def2f19 (HEAD -> master, origin/master, origin/HEAD)
Author: I3DBeeTech <129617321+I3DBeeTech@users.noreply.github.com>
Date:   Tue Jan 2 22:01:30 2024 +0530

    config: I3DBEEZ9 New board (#6447)
    
    Signed-off-by: Venkata Kamesh <i3dbee@gmail.com>
```

## printer.cfg

Klipperの設定ファイルは互換性がなくなっているのでドキュメントを見るかサンプルコンフィグ（configディレクトリ以下にあります）を見て必要なところを修正していきます。

[Configuration Changes - Klipper documentation](https://www.klipper3d.org/Config_Changes.html)

ドキュメントをざっと見たところ修正が必要そうなところは[rotation_distance](https://www.klipper3d.org/Rotation_Distance.html)だけでしたのでサンプルの該当箇所を見ながら直していきました。  
`rotation_distance`はステッピングモーターによるところのようだったので `printer-creality-ender3pro-2020.cfg`を参考に、その他のコメントは `generic-bigtreetech-skr-v1.3.cfg`をもとに追加しておきました。
※本来 `rotation_distance` は以下のように計算できるようなのでハードウェアの仕様を調べればよいのですが横着しました。

[Rotation distance - Klipper documentation](https://www.klipper3d.org/Rotation_Distance.html)

差分はこんな感じ。

``` diff
--- printer.cfg.bak     2022-11-16 00:25:03.602359503 +0900
+++ printer.cfg 2024-01-03 23:39:21.849433768 +0900
@@ -8,7 +8,8 @@
 step_pin: P2.2
 dir_pin: !P2.6
 enable_pin: !P2.1
-step_distance: .0125
+microsteps: 16
+rotation_distance: 40
 endstop_pin: P1.29  # P1.28 for X-max
 position_endstop: 0
 position_max: 320
@@ -18,7 +19,8 @@
 step_pin: P0.19
 dir_pin: !P0.20
 enable_pin: !P2.8
-step_distance: .0125
+microsteps: 16
+rotation_distance: 40
 endstop_pin: P1.27  # P1.26 for Y-max
 position_endstop: 0
 position_max: 300
@@ -28,7 +30,8 @@
 step_pin: P0.22
 dir_pin: P2.11
 enable_pin: !P0.21
-step_distance: .0025
+microsteps: 16
+rotation_distance: 8
 endstop_pin: probe:z_virtual_endstop
 position_max: 250
 position_min: -1.5
@@ -37,7 +40,8 @@
 step_pin: P2.13
 dir_pin: !P0.11
 enable_pin: !P2.12
-step_distance: .010526
+microsteps: 16
+rotation_distance: 34.406
 nozzle_diameter: 0.400
 filament_diameter: 1.750
 heater_pin: P2.7
@@ -98,30 +102,35 @@
 #[tmc2208 stepper_x]
 #uart_pin: P1.17
 #run_current: 0.800
+#stealthchop_threshold: 999999
 #hold_current: 0.500
 #stealthchop_threshold: 250
 
 #[tmc2208 stepper_y]
 #uart_pin: P1.15
 #run_current: 0.800
+#stealthchop_threshold: 999999
 #hold_current: 0.500
 #stealthchop_threshold: 250
 
 #[tmc2208 stepper_z]
 #uart_pin: P1.10
 #run_current: 0.650
+#stealthchop_threshold: 999999
 #hold_current: 0.450
 #stealthchop_threshold: 30
 
 #[tmc2208 extruder]
 #uart_pin: P1.8
 #run_current: 0.800
+#stealthchop_threshold: 999999
 #hold_current: 0.500
 #stealthchop_threshold: 5
 
 #[tmc2208 extruder1]
 #uart_pin: P1.1
 #run_current: 0.800
+#stealthchop_threshold: 999999
 #hold_current: 0.500
 #stealthchop_threshold: 5
 
@@ -141,6 +150,7 @@
 #spi_software_sclk_pin: P0.4
 ##diag1_pin: P1.29
 #run_current: 0.800
+#stealthchop_threshold: 999999
 #hold_current: 0.500
 #stealthchop_threshold: 250
 
@@ -151,6 +161,7 @@
 #spi_software_sclk_pin: P0.4
 ##diag1_pin: P1.27
 #run_current: 0.800
+#stealthchop_threshold: 999999
 #hold_current: 0.500
 #stealthchop_threshold: 250
 
@@ -161,6 +172,7 @@
 #spi_software_sclk_pin: P0.4
 ##diag1_pin: P1.25
 #run_current: 0.650
+#stealthchop_threshold: 999999
 #hold_current: 0.450
 #stealthchop_threshold: 30
 
@@ -171,6 +183,7 @@
 #spi_software_sclk_pin: P0.4
 ##diag1_pin: P1.28
 #run_current: 0.800
+#stealthchop_threshold: 999999
 #hold_current: 0.500
 #stealthchop_threshold: 5
 
@@ -181,6 +194,7 @@
 #spi_software_sclk_pin: P0.4
 ##diag1_pin: P1.26
 #run_current: 0.800
+#stealthchop_threshold: 999999
 #hold_current: 0.500
 #stealthchop_threshold: 5
```

修正後はサービスを再起動

``` shell
systemctl restart klipper
```

値については確信がなかったので実際に印刷してみてテストしました。

以上

↓今欲しい3Dプリンター

{{< affiliate asin="B0C2PJFLC5" title="Creality K1 MAX 3Dプリンター 600mm/S高速 300℃高温 AIカメラ アラーム Wifi印刷可能 ハンズフリー自動レベリング エアフィルター Core-XY構造 高精度印刷300x300x300mm 組み立て無し FDM 3dプリンタ本体 業務用 家庭用 " >}}

# 参考

* [OctoPrint.org - Upgrade your OctoPrint install to Python 3!](https://octoprint.org/blog/2020/09/10/upgrade-to-py3/)
* [Frequently Asked Questions - Klipper documentation](https://www.klipper3d.org/FAQ.html?h=update#how-do-i-upgrade-to-the-latest-software)
* [SDCard updates - Klipper documentation](https://www.klipper3d.org/SDCard_Updates.html)
* [Rotation distance - Klipper documentation](https://www.klipper3d.org/Rotation_Distance.html)
