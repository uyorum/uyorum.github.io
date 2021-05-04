+++
date = "2018-06-12T10:19:17+09:00"
slug = ""
tags = ["",""]
title = "必要最低限の設定で監視エージェントに監視させる"
aliases = ["/blog/security-settings-for-zabbix-agent/"]

+++

監視エージェントで監視をする際に，**必要最低限の**権限設定で監視できるようにしてみる．  
Zabbix Agentを例にとって記述するが，他の監視エージェントでも同様のことが言えると思う．

なお，ここでは監視に必要な必要最低限の権限を付与するという点を最優先した設定を考える．運用を考えると必ずしも最適とは言えない可能性があるため注意が必要．

<!--more-->

## 環境

``` shell
$ cat /etc/redhat-release
CentOS Linux release 7.5.1804 (Core)
$ yum list installed zabbix-agent
zabbix-agent.x86_64                3.4.10-1.el7                     @zabbix
```

## 実行ユーザ
エージェントの実行ユーザは`root`などの特別な権限を持ったユーザは避ける．
Zabbix Agentではデフォルトで`zabbix`ユーザで実行するようになっているためそのままにする．

``` shell
$ ps -ef | grep [z]abbix
zabbix    9075     1  0 01:23 ?        00:00:00 /usr/sbin/zabbix_agentd -c /etc/zabbix/zabbix_agentd.conf
zabbix    9076  9075  0 01:23 ?        00:00:00 /usr/sbin/zabbix_agentd: collector [idle 1 sec]
zabbix    9077  9075  0 01:23 ?        00:00:00 /usr/sbin/zabbix_agentd: listener #1 [waiting for connection]
zabbix    9078  9075  0 01:23 ?        00:00:00 /usr/sbin/zabbix_agentd: listener #2 [waiting for connection]
zabbix    9079  9075  0 01:23 ?        00:00:00 /usr/sbin/zabbix_agentd: listener #3 [waiting for connection]
zabbix    9080  9075  0 01:23 ?        00:00:00 /usr/sbin/zabbix_agentd: active checks #1 [idle 1 sec]
```

## パーミッション
このままでも各種メトリクスは取得できるが，ログ監視のために追加の設定が必要となる．
例えば`/var/log/messages`は以下のような権限が設定されており，そのままだと`zabbix`ユーザでは監視することができない．

``` shell
$ ls -l /var/log/messages
-rw-------. 1 root root 75591  6月 10 02:35 /var/log/messages
$ sudo su -s /bin/sh zabbix sh -c 'tail /var/log/messages'
tail: cannot open '/var/log/messages' for reading: Permission denied
```

zabbixユーザでファイルを開けるようにするには以下のような設定が考えられる．

rootグループに対して読み取り権限を設定しzabbixユーザをrootグループに所属させる

    ``` shell
    $ sudo usermod -a -G root zabbix
    $ sudo chmod g+r /var/log/messages
    ```

これでログを開けるようになる．さらに少ない権限でいくなら[アクセスACL](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/system_administrators_guide/acls-setting)という機能が使える．  
この機能を使えば特定のユーザに対して特定のファイルにのみ権限を設定することができる．

``` shell
$ getfacl /var/log/messages
getfacl: Removing leading '/' from absolute path names
# file: var/log/messages
# owner: root
# group: root
user::rw-
group::---
other::---
$ sudo setfacl -m u:zabbix:r /var/log/messages
$ sudo getfacl /var/log/messages
getfacl: Removing leading '/' from absolute path names
# file: var/log/messages
# owner: root
# group: root
user::rw-
user:zabbix:r--
group::---
mask::r--
other::---
```

## SELinux
上の設定だけでは不十分で，実際にはSELinuxによりZabbix Agentは/var/log/messagesを開くことはできない．
audit.logには以下のようなログが記録される．

``` shell
$ sudo ausearch -c 'zabbix_agentd'
time->Tue Jun 12 13:25:06 2018
type=PROCTITLE msg=audit(1528809906.258:3512): proctitle=2F7573722F7362696E2F7A61626269785F6167656E74643A2061637469766520636865636B73202331205B70726F63657373696E672061637469766520636865636B735D
type=SYSCALL msg=audit(1528809906.258:3512): arch=c000003e syscall=2 success=no exit=-13 a0=55745cdc7ee0 a1=0 a2=0 a3=2 items=0 ppid=14622 pid=14627 auid=4294967295 uid=997 gid=994 euid=997 suid=997 fsuid=997 egid=994 sgid=994 fsgid=994 tty=(none) ses=4294967295 comm="zabbix_agentd" exe="/usr/sbin/zabbix_agentd" subj=system_u:system_r:zabbix_agent_t:s0 key=(null)
type=AVC msg=audit(1528809906.258:3512): avc:  denied  { read } for  pid=14627 comm="zabbix_agentd" name="messages" dev="sda1" ino=8802128 scontext=system_u:system_r:zabbix_agent_t:s0 tcontext=system_u:object_r:var_log_t:s0 tclass=file
```

これを許可するようなBooleanもなさそう

``` shell
$ sudo semanage boolean -l | grep zabbix
zabbix_can_network             (off  ,  off)  Allow zabbix to can network
httpd_can_connect_zabbix       (off  ,  off)  Allow httpd to can connect zabbix
```

そのため独自の許可ルールを作成することになる

SELinuxをPermissiveモードにして拒否されるであろう動作を洗い出す

``` shell
$ sudo setenforce 0
(しばらく待つ)
$ sudo ausearch -c 'zabbix_agentd'
time->Tue Jun 12 13:40:21 2018
type=PROCTITLE msg=audit(1528810821.374:3621): proctitle=2F7573722F7362696E2F7A61626269785F6167656E74643A2061637469766520636865636B73202331205B70726F63657373696E672061637469766520636865636B735D
type=SYSCALL msg=audit(1528810821.374:3621): arch=c000003e syscall=2 success=yes exit=6 a0=55745cdc7ee0 a1=0 a2=0 a3=2 items=0 ppid=14622 pid=14627 auid=4294967295 uid=997 gid=994 euid=997 suid=997 fsuid=997 egid=994 sgid=994 fsgid=994 tty=(none) ses=4294967295 comm="zabbix_agentd" exe="/usr/sbin/zabbix_agentd" subj=system_u:system_r:zabbix_agent_t:s0 key=(null)
type=AVC msg=audit(1528810821.374:3621): avc:  denied  { open } for  pid=14627 comm="zabbix_agentd" path="/var/log/messages" dev="sda1" ino=8802128 scontext=system_u:system_r:zabbix_agent_t:s0 tcontext=system_u:object_r:var_log_t:s0 tclass=file
type=AVC msg=audit(1528810821.374:3621): avc:  denied  { read } for  pid=14627 comm="zabbix_agentd" name="messages" dev="sda1" ino=8802128 scontext=system_u:system_r:zabbix_agent_t:s0 tcontext=system_u:object_r:var_log_t:s0 tclass=file
```

カスタムルールを生成して読み込ませる

``` shell
$ sudo ausearch -c 'zabbix_agentd' --raw | audit2allow -M my-zabbixagentd
$ cat my-zabbixagentd.te

module my-zabbixagentd 1.0;

require {
        type var_log_t;
        type zabbix_agent_t;
        class file { open read };
}

#============= zabbix_agent_t ==============
allow zabbix_agent_t var_log_t:file { open read };
$ sudo semodule -i my-zabbixagentd.pp
```

これでログが読めるようになる．
ちなみにSELinuxによる拒否が発生した場合に必要なアクションを調べるには`setroubleshoot`パッケージが便利．

監視内容によってはまだ追加の設定が必要になると思うが，基本的には上の考え方を応用すれば設定できるはず．

<iframe style="width:120px;height:240px;" marginwidth="0" marginheight="0" scrolling="no" frameborder="0" src="//rcm-fe.amazon-adsystem.com/e/cm?lt1=_blank&bc1=000000&IS2=1&bg1=FFFFFF&fc1=000000&lc1=0000FF&t=uyorum-22&language=ja_JP&o=9&p=8&l=as4&m=amazon&f=ifr&ref=as_ss_li_til&asins=B085KTYH49&linkId=7556aa52a54d25a47637393fcce218d6"></iframe>

## 参考

* [5.2. Setting Access ACLs - Red Hat Customer Portal](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/system_administrators_guide/acls-setting)
* [8.3. Fixing Problems - Red Hat Customer Portal](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/security-enhanced_linux/sect-security-enhanced_linux-troubleshooting-fixing_problems)
