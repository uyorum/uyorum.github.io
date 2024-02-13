+++
slug = ""
tags = ["docker", "epgstation"]
title = "Docker Build Cloudを試す"
date = "2024-02-13T16:12:00+09:00"
+++

Docker Build Cloudがリリースされたので、試しにかねてよりアウトソースしたいと思っていた[EPGStation on RaspberryPi用のイメージビルド](../raspberrypi-mirakurun-epgstation/)を実装してみます。

<!--more-->

# 対象

ビルドしたいDockerfileは[ここ](https://github.com/uyorum/rpi-docker-mirakurun-epgstation/blob/v2/epgstation/debian.Dockerfile)にあります。
ラズパイ上で動かすイメージのため、アーキテクチャは`Arm/v7`向けのみビルドします。

# 全体的な構成

登場人物と全体的な流れは以下の通りになります。

1. GitHubへのプッシュをトリガーにWodkflowを実行
2. Workflow内で以下の処理を実行
    1. DockerHubへログイン
    2. Docker Build Cloudへビルド要求をリクエスト
3. Docker Build Cloud（Builder）上でイメージがビルドされる
4. イメージをBuilderからDocker Hubへ直接アップロード

なお `Arm/v7` でのビルドはDocker Build Cloud（buildx）で実現するためGitHub Actionsは通常通り `amd64` でOKです。

# 設定

## Docker Build Cloud

1. [Docker Build Cloud](https://build.docker.com/)へログインします
2. プランを選択します  
    今回はお試しということで無償プランの「Starter」を選択します
3. Builderを作成します  
    Builderとは、イメージをビルドするためのインスタンスで、実体はBuildKitというデーモンです。  
    BuilderはBuild Cloud以前からある概念のようで、元来は自分たちで用意するものだったようです。  
    つまりDocker Build CloudはBuilderが提供されるクラウドサービスということができそうです。

## GitHub（リポジトリ）

- リポジトリシークレットを作成します
    1. リポジトリのSettings > Secrets and variables > Actions
    2. Repository secretsから2つのシークレットを作成し、それぞれDockerHubログイン時に使う値を設定しておきます
        - `DOCKER_USER`
        - `DOCKER_PASSWORD`

## ワークフローファイル

リポジトリ内にワークフローファイルを作成しGitHubへプッシュします。  
文法は[公式ドキュメント](https://docs.docker.com/build/cloud/ci/)を参考に。  
今回作成したファイルは[こちら](https://github.com/uyorum/rpi-docker-mirakurun-epgstation/blob/v2/.github/workflows/docker-build.yml)。

### docker/build-push-action@v5

公式ドキュメントのサンプルでは説明が不足していますが、利用できるオプションは[ここ](https://github.com/docker/build-push-action)から確認できます。  
ターゲットのアーキテクチャは `platform` オプションで指定できます。利用可能な値は[ここ](https://docs.docker.com/engine/reference/commandline/buildx_build/#platform)から確認できます。

```yaml
- name: Build and push
  uses: docker/build-push-action@v5
  with:
    context: "./epgstation"
    file: "./epgstation/debian.Dockerfile"
    tags: "uyorum/rpi-mirakurun-epgstation"
    platforms: linux/arm/v7
    # For pull requests, export results to the build cache.
    # Otherwise, push to a registry.
    outputs: ${{ github.event_name == 'pull_request' && 'type=cacheonly' || 'type=registry,push=true' }}
```

ここまで正しく設定できていればワークフローが自動で始まりDockerHubへイメージがプッシュされるはずです。

# Docker Build Cloudを使うメリット

Buildxを使うことによるメリットと、さらにBuilderがクラウドで提供されることによるメリットがあります。  
前者は主に「開発中とCIの両方でビルド環境を共有できること」にあると思います。今回は触れませんでしたが、うまく設定することでキャッシュの共有などを行い、チーム全体の作業時間を短縮することができそうです。  
後者は言わずもがな、Builderの管理負荷の軽減でしょう。  
なお、実は今回対象にしたイメージはビルド中にffmpegのコンパイルも行っています。これまではラズパイ上でこのコンパイルを行っていたためイメージのビルドに40分以上かかっていました。今回Docker Build Cloudをつかうことでここの高速化も密かに期待していましたが、[結果的に30分以上かかっている](https://github.com/uyorum/rpi-docker-mirakurun-epgstation/actions/runs/7684924144)ため、単純なCPU性能はそこまで高くなさそうです。  
ここについてはDockerfileを調整してもう少し時間短縮をしてみようと思います。

# 参照

[Docker Build Cloud | Docker Docs](https://docs.docker.com/build/cloud/)

[Docker Buildx | Docker ドキュメント](https://matsuand.github.io/docs.docker.jp.onthefly/buildx/working-with-buildx/)
