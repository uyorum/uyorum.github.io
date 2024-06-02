+++
slug = ""
tags = ["openshift"]
title = "Microshiftでtopolvmを使ってPVをを作成する"
date = "2024-06-02T11:34:03+09:00"
+++

[前回](../setup-microshift/)セットアップしたMicroShiftではLVMシンプールを使ってPVを作成するように設定したので、各種動作を確認してみます。

<!--more-->

## 設定内容

前回、デバイスクラスを作成しました。

``` shell
$ sudo cat /etc/microshift/lvmd.yaml
socket-name:
device-classes:
  - name: thin
    default: true
    spare-gb: 0
    thin-pool:
      name: ocpthinpool
      overprovision-ratio: 10
    type: thin
    volume-group: rhel
```

「デバイスクラス」の明確な定義は見つかりませんでしたが、topolvmが使用するバックエンド（VG）を指しているようで、HDDやSSD、RAIDなど、ストレージのプロファイルに対応する概念のようです。  
cf. [lvmd.md](https://github.com/topolvm/topolvm/blob/main/docs/lvmd.md)

topolvmを使用する[ストレージクラス](https://kubernetes.io/ja/docs/concepts/storage/storage-classes/)はデフォルトで1つ存在します。

``` shell
$ oc get storageclasses.storage.k8s.io topolvm-provisioner -o yaml
allowVolumeExpansion: true
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
  creationTimestamp: "2024-04-06T10:06:36Z"
  name: topolvm-provisioner
  resourceVersion: "391"
  uid: 29bf1ab6-82c2-4274-9aeb-ea099306cf51
parameters:
  csi.storage.k8s.io/fstype: xfs
provisioner: topolvm.io
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
```

ストレージクラスの方も「プロファイル」に対応する概念のようなのでストレージクラスとデバイスクラスは１：１に対応するように設定するのがわかりやすそうですが、
今回はストレージもローカルディスク１つしかないのでデフォルトのストレージクラスをそのまま使います。

## PVを作成する

まずは上の設定を使ってPVを作って適当なコンテナへアタッチしてみます。

``` shell
$ oc apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-claim-thin
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: topolvm-provisioner
---
apiVersion: v1
kind: Pod
metadata:
  name: base
spec:
  containers:
  - image: docker.io/nginx:stable-alpine
    name: test-container
    volumeMounts:
    - mountPath: /vol
      name: test-vol
  volumes:
  - name: test-vol
    persistentVolumeClaim:
      claimName: test-claim-thin
EOF
persistentvolumeclaim/test-claim-thin created
pod/base created
```

PVが作成されました。

``` shell
$ oc get pvc
NAME              STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS          AGE
test-claim-thin   Bound    pvc-f8c20f2e-7d1a-4a3d-a2b0-e6d942c044dc   1Gi        RWO            topolvm-provisioner   50s
$ oc get pv pvc-f8c20f2e-7d1a-4a3d-a2b0-e6d942c044dc
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                     STORAGECLASS          REASON   AGE
pvc-f8c20f2e-7d1a-4a3d-a2b0-e6d942c044dc   1Gi        RWO            Delete           Bound    default/test-claim-thin   topolvm-provisioner            82s
$ oc describe pv pvc-f8c20f2e-7d1a-4a3d-a2b0-e6d942c044dc
Name:              pvc-f8c20f2e-7d1a-4a3d-a2b0-e6d942c044dc
Labels:            <none>
Annotations:       pv.kubernetes.io/provisioned-by: topolvm.io
                   volume.kubernetes.io/provisioner-deletion-secret-name:
                   volume.kubernetes.io/provisioner-deletion-secret-namespace:
Finalizers:        [kubernetes.io/pv-protection]
StorageClass:      topolvm-provisioner
Status:            Bound
Claim:             default/test-claim-thin
Reclaim Policy:    Delete
Access Modes:      RWO
VolumeMode:        Filesystem
Capacity:          1Gi
Node Affinity:
  Required Terms:
    Term 0:        topology.topolvm.io/node in [beelink]
Message:
Source:
    Type:              CSI (a Container Storage Interface (CSI) volume source)
    Driver:            topolvm.io
    FSType:            xfs
    VolumeHandle:      1d0a104e-8655-4de8-a62c-827498301575
    ReadOnly:          false
    VolumeAttributes:      storage.kubernetes.io/csiProvisionerIdentity=1713637484909-2854-topolvm.io
Events:                <none>
$ sudo lvs
  LV                                   VG   Attr       LSize   Pool        Origin Data%  Meta%  Move Log Cpy%Sync Convert
  1d0a104e-8655-4de8-a62c-827498301575 rhel Vwi-aotz--   1.00g ocpthinpool        6.32
  ocpthinpool                          rhel twi-aotz-- 100.00g                    0.06   10.45
  root                                 rhel -wi-ao---- 100.00g
  swap                                 rhel -wi-ao----  <7.76g
```

設定した通り、シンプールを通してLVが作成されていることがわかります。

## スナップショット

スナップショットとは、

[Storage Red Hat build of MicroShift 4.15 | Red Hat Customer Portal](https://access.redhat.com/documentation/ja-jp/red_hat_build_of_microshift/4.15/html-single/storage/index#microshift-volume-snapshot-classes_volume-snapshots-microshift)
[ボリュームのスナップショット | Kubernetes](https://kubernetes.io/ja/docs/concepts/storage/volume-snapshots/)

> ボリュームスナップショットは、完全に新しいボリュームを作成することなく、特定の時点でボリュームの内容をコピーするための標準化された方法をKubernetesユーザーに提供します。この機能により、たとえばデータベース管理者は、編集または削除の変更を実行する前にデータベースをバックアップできます。

スナップショットを作成するため、スナップショットクラスを作成します。

``` shell
$ oc apply -f - <<EOF
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: topolvm-snapclass
  annotations:
    snapshot.storage.kubernetes.io/is-default-class: "true" 
driver: topolvm.io 
deletionPolicy: Delete 
EOF
```

このPVのスナップショットを作成します。
ですが、試しにPodを止めずにスナップショットを作成した際はPVへの書き込みはほとんどないにも関わらず出来上がったLVMスナップショットをマウントできませんでした。


``` shell
$ sudo mount /dev/rhel/e1bd464a-c351-4173-8bd8-b5234d9b2279 /mnt/snapshot
mount: /mnt/snapshot: cannot mount /dev/mapper/rhel-e1bd464a--c351--4173--8bd8--b5234d9b2279 read-only.
```

PVへの書き込みを停止するためにあらかじめPodを削除します。

``` shell
$ oc delete pod base
pod "base" deleted
$ oc get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                     STORAGECLASS          REASON   AGE
pvc-f8c20f2e-7d1a-4a3d-a2b0-e6d942c044dc   1Gi        RWO            Delete           Bound    default/test-claim-thin   topolvm-provisioner            35s
$ oc apply -f - <<EOF
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: test-snapshot
spec:
  volumeSnapshotClassName: topolvm-snapclass
  source:
    persistentVolumeClaimName: test-claim-thin
EOF
volumesnapshot.snapshot.storage.k8s.io/test-snapshot created
```

作成されたようです。取得したスナップショットの情報を確認してみます。

``` shell
$ oc get volumesnapshot
NAME            READYTOUSE   SOURCEPVC         SOURCESNAPSHOTCONTENT   RESTORESIZE   SNAPSHOTCLASS       SNAPSHOTCONTENT                                    CREATIONTIME   AGE
test-snapshot   true         test-claim-thin                           1Gi           topolvm-snapclass   snapcontent-a8443d82-ac86-448d-b068-ddb09eecbb9c   32s            33s
$ sudo lvs
  LV                                   VG   Attr       LSize   Pool        Origin                               Data%  Meta%  Move Log Cpy%Sync Convert
  4adb15e6-2d9e-46dc-a3a1-a9e4ef405627 rhel Vri-a-tz--   1.00g ocpthinpool 1d0a104e-8655-4de8-a62c-827498301575 6.32
  1d0a104e-8655-4de8-a62c-827498301575 rhel Vwi-aotz--   1.00g ocpthinpool                                      6.32
  ocpthinpool                          rhel twi-aotz-- 100.00g                                                  0.06   10.45
  root                                 rhel -wi-ao---- 100.00g
  swap                                 rhel -wi-ao----  <7.76g
```

LVMのレイヤでは対象のLVから（LVMの）スナップショットを取得していることがわかります。  
ただしこのままではこのホストが壊れたらスナップショットも失われてしまうためバックアップとしては弱いです。
きちんと障害に備えるにはこのスナップショットを別のハードウェア等に退避しておいたほうがよいです。

``` shell
$ sudo mkdir /mnt/snapshot
$ sudo mount /dev/rhel/4adb15e6-2d9e-46dc-a3a1-a9e4ef405627 /mnt/snapshot/
mount: /mnt/snapshot: WARNING: source write-protected, mounted read-only.sudo mount /dev/ /mnt/snapshot
$ sudo cp -a /mnt/snapshot DESTINATION
```

## スナップショットからリストア

スナップショットからPVCを作ってPodへアタッチします。

``` shell
$ oc apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: snapshot-restore
spec:
  accessModes:
  - ReadWriteOnce
  dataSource:
    apiGroup: snapshot.storage.k8s.io
    kind: VolumeSnapshot
    name: test-snapshot
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: base
spec:
  containers:
  - image: docker.io/nginx:stable-alpine
    name: test-container
    volumeMounts:
    - mountPath: /vol
      name: test-vol
  volumes:
  - name: test-vol
    persistentVolumeClaim:
      claimName: snapshot-restore
EOF
persistentvolumeclaim/snapshot-restore created
pod/base created
$ oc get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                      STORAGECLASS          REASON   AGE
pvc-462ea98a-e038-4218-8418-eaf56d6d5f8f   1Gi        RWO            Delete           Bound    default/snapshot-restore   topolvm-provisioner            23h
pvc-9aa6b184-f7b5-4cbd-9948-26cccfd9a107   1Gi        RWO            Delete           Bound    default/test-claim-thin    topolvm-provisioner            24h
$ oc describe pv pvc-462ea98a-e038-4218-8418-eaf56d6d5f8f
Name:              pvc-462ea98a-e038-4218-8418-eaf56d6d5f8f
Labels:            <none>
Annotations:       pv.kubernetes.io/provisioned-by: topolvm.io
                   volume.kubernetes.io/provisioner-deletion-secret-name:
                   volume.kubernetes.io/provisioner-deletion-secret-namespace:
Finalizers:        [kubernetes.io/pv-protection]
StorageClass:      topolvm-provisioner
Status:            Bound
Claim:             default/snapshot-restore
Reclaim Policy:    Delete
Access Modes:      RWO
VolumeMode:        Filesystem
Capacity:          1Gi
Node Affinity:
  Required Terms:
    Term 0:        topology.topolvm.io/node in [beelink]
Message:
Source:
    Type:              CSI (a Container Storage Interface (CSI) volume source)
    Driver:            topolvm.io
    FSType:            xfs
    VolumeHandle:      1a36fc28-9e75-45a2-a8d2-7444c3ada58e
    ReadOnly:          false
    VolumeAttributes:      storage.kubernetes.io/csiProvisionerIdentity=1714679255467-5370-topolvm.io
Events:                <none>
$ sudo lvs
  LV                                   VG   Attr       LSize   Pool        Origin                               Data%  Meta%  Move Log Cpy%Sync Convert
  1a36fc28-9e75-45a2-a8d2-7444c3ada58e rhel Vwi-aotz--   1.00g ocpthinpool 4adb15e6-2d9e-46dc-a3a1-a9e4ef405627 6.32
  4adb15e6-2d9e-46dc-a3a1-a9e4ef405627 rhel Vri-a-tz--   1.00g ocpthinpool 1d0a104e-8655-4de8-a62c-827498301575 6.32
  1d0a104e-8655-4de8-a62c-827498301575 rhel Vwi-a-tz--   1.00g ocpthinpool                                      6.32
  ocpthinpool                          rhel twi-aotz-- 100.00g                                                  0.07   10.46
  root                                 rhel -wi-ao---- 100.00g
  swap                                 rhel -wi-ao----  <7.76g
```

LVMレイヤでは、LVMスナップショットから新たなLVが作成されています。

## スナップショットの削除

スナップショットの削除時に実体となるLVを削除するかどうかをVolumeSnapshotClassで設定できます。  
VolumeSnapshotClass（再掲）

``` shell
$ oc apply -f - <<EOF
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: topolvm-snapclass
  annotations:
    snapshot.storage.kubernetes.io/is-default-class: "true" 
driver: topolvm.io 
deletionPolicy: Delete 
EOF
```

`deletionPolicy`をDeleteに設定した場合、VolumeSnapshotの削除と同時に実体のLV（MicroShift上ではVolumeSnapshotContentリソースとして管理されています）も削除されます。
Retainに設定した場合はVolumeSnapshotContentが削除されずに残ります。


``` shell
$ oc delete volumesnapshot test-snapshot
volumesnapshot.snapshot.storage.k8s.io "test-snapshot" deleted
$ sudo lvs
  LV                                   VG   Attr       LSize   Pool        Origin Data%  Meta%  Move Log Cpy%Sync Convert
  1a36fc28-9e75-45a2-a8d2-7444c3ada58e rhel Vwi-aotz--   1.00g ocpthinpool        6.32
  1d0a104e-8655-4de8-a62c-827498301575 rhel Vwi-a-tz--   1.00g ocpthinpool        6.32
  ocpthinpool                          rhel twi-aotz-- 100.00g                    0.07   10.46
  root                                 rhel -wi-ao---- 100.00g
  swap                                 rhel -wi-ao----  <7.76g
```

Retainに設定した場合：

``` shell
$ oc patch volumesnapshotclass topolvm-snapclass --type='json' -p='[{"op": "replace", "path": "/deletionPolicy", "value":"Retain"}]'
volumesnapshotclass.snapshot.storage.k8s.io/topolvm-snapclass patched
$ oc apply -f - <<EOF
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: test-snapshot-retain
spec:
  volumeSnapshotClassName: topolvm-snapclass
  source:
    persistentVolumeClaimName: test-claim-thin
EOF
volumesnapshot.snapshot.storage.k8s.io/test-snapshot-retain created
$ oc get volumesnapshot test-snapshot-retain
NAME                   READYTOUSE   SOURCEPVC         SOURCESNAPSHOTCONTENT   RESTORESIZE   SNAPSHOTCLASS       SNAPSHOTCONTENT                                    CREATIONTIME   AGE
test-snapshot-retain   true         test-claim-thin                           1Gi           topolvm-snapclass   snapcontent-31631ab1-a663-4436-b0b6-d19e538364e8   45s            45s
$ oc get volumesnapshotcontent
NAME                                               READYTOUSE   RESTORESIZE   DELETIONPOLICY   DRIVER       VOLUMESNAPSHOTCLASS   VOLUMESNAPSHOT         VOLUMESNAPSHOTNAMESPACE   AGE
snapcontent-31631ab1-a663-4436-b0b6-d19e538364e8   true         1073741824    Retain           topolvm.io   topolvm-snapclass     test-snapshot-retain   default                   72s
$ oc delete volumesnapshot test-snapshot-retain
volumesnapshot.snapshot.storage.k8s.io "test-snapshot-retain" deleted
$ oc get volumesnapshotcontent
NAME                                               READYTOUSE   RESTORESIZE   DELETIONPOLICY   DRIVER       VOLUMESNAPSHOTCLASS   VOLUMESNAPSHOT         VOLUMESNAPSHOTNAMESPACE   AGE
snapcontent-31631ab1-a663-4436-b0b6-d19e538364e8   true         1073741824    Retain           topolvm.io   topolvm-snapclass     test-snapshot-retain   default                   5m14s
$ oc get volumesnapshotcontent snapcontent-31631ab1-a663-4436-b0b6-d19e538364e8 -o jsonpath='{.status.snapshotHandle}'
92d06036-12de-4600-877a-113ec5e21932
$ sudo lvs
  LV                                   VG   Attr       LSize   Pool        Origin                               Data%  Meta%  Move Log Cpy%Sync Convert
  92d06036-12de-4600-877a-113ec5e21932 rhel Vri-a-tz--   1.00g ocpthinpool cd059561-dcd6-4afd-9c22-f370f6caf6aa 6.32
  cd059561-dcd6-4afd-9c22-f370f6caf6aa rhel Vwi-a-tz--   1.00g ocpthinpool                                      6.32
  ocpthinpool                          rhel twi-aotz-- 100.00g                                                  0.07   10.46
  root                                 rhel -wi-ao---- 100.00g
  swap                                 rhel -wi-ao----  <7.76g
```

VolumeSnapshotを削除しても実体のLV（`92d06036-12de-4600-877a-113ec5e21932`）が残っていることがわかります。
実体も削除する場合はVolumeSnapshotContentを削除します。

``` shell
$ oc delete volumesnapshotcontent snapcontent-31631ab1-a663-4436-b0b6-d19e538364e8
volumesnapshotcontent.snapshot.storage.k8s.io "snapcontent-31631ab1-a663-4436-b0b6-d19e538364e8" deleted
$ sudo lvs
  LV                                   VG   Attr       LSize   Pool        Origin                               Data%  Meta%  Move Log Cpy%Sync Convert
  92d06036-12de-4600-877a-113ec5e21932 rhel Vri-a-tz--   1.00g ocpthinpool cd059561-dcd6-4afd-9c22-f370f6caf6aa 6.32
  cd059561-dcd6-4afd-9c22-f370f6caf6aa rhel Vwi-a-tz--   1.00g ocpthinpool                                      6.32
  ocpthinpool                          rhel twi-aotz-- 100.00g                                                  0.07   10.46
  root                                 rhel -wi-ao---- 100.00g
  swap                                 rhel -wi-ao----  <7.76g
```

これが正常動作なのかはわかりませんが、上の通りVolumeSnapshotContentを削除してもLVが残ってしまいました。

``` shell
$ sudo lvremove rhel/92d06036-12de-4600-877a-113ec5e21932
  Logical volume "92d06036-12de-4600-877a-113ec5e21932" successfully removed.
```

最後の動作が想定外でしたが、概ね動作を理解できました。

{{< affiliate asin="B09MQ54CLV" title="OpenShift徹底入門" >}}
