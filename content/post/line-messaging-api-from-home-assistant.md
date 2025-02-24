+++
slug = ""
tags = ["Home Assistant", "LINE"]
title = "Home AssistantからLine Messaging APIを実行する"
date = "2025-02-25T01:42:47+09:00"
+++

[Line Notifyがサービス終了する](https://notify-bot.line.me/closing-announce)ということで、代替として推奨されているMessaging APIでメッセージをポストするように設定していきます。

<!--more-->

## LINE Botの設定

まず、LINE Botを作成し、チャネルアクセストークンを取得します。  
手順については、以下の記事などを参考にしてください。  
（参考: [LINE公式アカウントの作成 / LINE Botの初め方 2025年更新](https://zenn.dev/protoout/articles/16-line-bot-setup)）

同じ画面にあるQRコードを使ってBotを友達登録しておきます。  
また、「チャネル基本設定」にある「あなたのユーザーID」を控えておきます。

## Home Assistantの設定

Home Assistant用のカスタムコンポーネントもありますが、LINE Messaging APIの仕様を確認したところ、メッセージ送信は単純なREST APIのようです。  
そこで、Home Assistantにデフォルトで備わっている[RESTful Notifications](https://www.home-assistant.io/integrations/notify.rest/)を使ってAPIを呼び出すことにします。

メッセージの仕様はいくつかありますが、特定のユーザーにメッセージを送信する[プッシュメッセージ](https://developers.line.biz/ja/reference/messaging-api/#send-push-message)を使います。  
まず、これを使って自分にメッセージを送信できるようにします。（メッセージを送信するには、あらかじめ友達登録が必要です）

私の環境ではHome Assistantの設定を別ファイルに分割しているため、それぞれのファイルに設定を記述します。通常は`configuration.yaml`に記述すれば問題ありません。

secret.yaml

``` yaml
line_channel_access_token: 'Bearer <上で確認したチャネルアクセストークン>'
```

notify.yaml

``` yaml
- name: LINE_me
  platform: rest
  resource: https://api.line.me/v2/bot/message/push
  method: POST_JSON
  headers:
    Authorization: !secret line_channel_access_token
    Content-Type: application/json
  data:
    to: <上で確認した自分のユーザーID>
    messages:
      - type: text
        text: "{{ message }}"
```

## グループLINEへの投稿

私は家族でLINEグループへLINE Notifyも追加して各種通知を送信していました。次はBotからこのグループに投稿するための設定も行っていきます。  
まずはあらかじめグループにBotを追加しておきます。

特定のグループにメッセージを送信するには、ユーザーIDの代わりに「グループID」を指定する必要があります。  
ですがこのグループID、GUIから確認する手段が用意されていません（少なくとも私は見つけられなかった）  
私はLINEのWebhook機能とHome AssistantのWebhook Triggerを使って取得しました。この方法を使うには、Home Assistantがインターネットに公開されている必要があります。

### グループID取得方法

1. LINE Botの設定画面でWebhookを有効にします  
    Webhook URLは「https://<Home Assistant公開ホスト名>/api/webhook/<Webhook Trigger名>」です。  
    Webhook Trigger名は任意の文字列です。このTrigger名をHome Assistantでも使います。
1. Home Assistantに以下のAutomationを作成します

    ``` yaml
    alias: Get LINE group ID
    triggers:
      - webhook_id: <上で設定したWebhook Trigger名>
        allowed_methods:
        - POST
        local_only: false
        trigger: webhook
    actions:
      - action: notify.line_me
        data:
          message: 'User ID: {{ trigger.json.events[0].source.userId }}'
      - action: notify.line_me
        data:
          message: 'Group ID: {{ trigger.json.events[0].source.groupId }}'
    ```

1. グループ内で発言します
1. Botから自分宛にグループIDと発言した人のユーザーIDが投稿されてきます

### グループ投稿用Notifyサービスの設定

取得したグループIDを使って、グループ投稿用のNotifyサービスを設定します。  
ID以外は上記の設定と同じです。

notify.yaml

``` yaml
- name: LINE_family
  platform: rest
  resource: https://api.line.me/v2/bot/message/push
  method: POST_JSON
  headers:
    Authorization: !secret line_channel_access_token
    Content-Type: application/json
  data:
    to: <グループID>
    messages:
      - type: text
        text: "{{ message }}"
```

以上で設定は完了です。  
LINE Notifyを使っていたAutomationを修正し、動作確認後、LINE Notify関連の設定を削除します。

以前使用していたカスタムコンポーネントを削除し、Home Assistantを再起動します。
各種設定ファイルからLINE Notifyに関する記述を削除すれば、置き換えは完了です。

以上です。

## 参考資料

* [Messaging APIリファレンス | LINE Developers](https://developers.line.biz/ja/reference/messaging-api/#send-push-message)
* [RESTful Notifications - Home Assistant](https://www.home-assistant.io/integrations/notify.rest/)
* [Automation Trigger - Home Assistant](https://www.home-assistant.io/docs/automation/trigger/#webhook-trigger)
