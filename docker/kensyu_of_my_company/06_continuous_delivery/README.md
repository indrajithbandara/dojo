# 継続的デリバリー
継続デリバリとはリリース資材への変更が発生すると、自動的にビルド、テスト及び本番へのリリース準備が実行されるプロセスのことを呼びます。
アジャイル開発手法などで取り入れられるプロセスです。  
今回はソースコードへの変更が発生した際に自動的にビルドとテストが実行されるまでの環境をDocker を使って構築してみたいと思います(今回のサンプルで実演するのは継続的インテグレーションレベルの話になります)。

# 構成概要
## アプリケーション構成
Git リポジトリをWeb で管理するGitLab とDrone を使います。
GitLab はGitHub のようにgit でソースコードを管理することができるもので、git でソースコードの変更が発生したときにDrone 環境のビルドとテストの実行を自動で行う環境を構築します。  
  
https://about.gitlab.com/
[GitLab](https://about.gitlab.com/ "GitLab")  
[Drone(GitHub)](https://github.com/drone/drone "Drone")  
  
なお、今回はGitLab とDrone もDocker コンテナで準備するようにします。  
  
[GitLab(Docker Hub)](https://hub.docker.com/r/gitlab/gitlab-ce/ "GitLab(Docker Hub)")  
[Drone(Docker Hub)](https://hub.docker.com/r/drone/drone/ "Drone(Docker Hub)")  

## ネットワーク構成
今回継続的デリバリのテスト環境を構築するために、事前に以下のような環境を準備しました。

```
+- サーバ(Linux) ---------------------------------------------+
|                                                             |
| +----------------+  +----------------+  +----------------+  |
| | GitLab         |  | Drone          |  | Bind(DNS)      |  |
| |                |  |                |  |                |  |
| +--+-------------+  +--+-------------+  +--+-------------+  |
|    |                   |                   |                |
| +--+-------------------+-------------------+-------------+  |
| | bridge interface(x.x.x.x)                              |  |
| +--+-------------------+-------------------+-------------+  |
|    |                   |                   |                |
| +--+------------+   +--+------------+   +--+------------+   |
+-| eth0          |---| eth0:1        |---| eth0:2        |---+
  | 192.168.1.41  |   | 192.168.1.42  |   | 192.168.1.43  |
  +--+------------+   +--+------------+   +--+------------+
     |                   |                   |
    ～～                ～～                ～～

  +----------------+
  | クライアント   |
  | 192.168.1.x    |
  +----------------+

* サーバ1 台とクライアント1 台を用意してください。サーバはVirtual Box などで構いません
* IP エイリアスを使って一つのホストマシン(サーバ)に複数のIP アドレスを割り当てます
* GitLab はホストOS 側のeth0(192.168.1.41) とバインドさせます
* Drone はホストOS 側のeth0:1(192.168.1.42) とバインドさせます
* Bind(DNS) はホストOS 側のeth0:2(192.168.43) とバインドさせます
* クライアント端末には事前にgitlab.example.com(192.168.1.41)とdrone.example.com(192.168.1.42) をhosts に登録しています(もしくは参照しているDNS サーバをBind に向けてしまってください)。
```

今回の構成ではGitLab とDrone は、別の場所にホスティングされていることを想定しています。
またDNS 実際はわざわざ自前で建てるのではなく、ドメイン取得サービスでGitLab とDrone が乗っているサーバのドメインを取得して済ませることを想定しています。

## 事前準備
本検証環境を問題なく動作させるために以下の手順を事前に実施しておいてください
* クライアントのhosts ファイルにgitlab.example.com(192.168.1.41)とdrone.example.com(192.168.1.42)を登録
* このリポジトリの.env ファイル内の`IP_FOR_GITLAB` にGitLab のIP、`IP_FOR_DRONE` にdrone、`IP_FOR_BIND` にdns のIP アドレスを記載してください
* bind/conf/example.com ファイル内に、GitLab とdrone のIP を記載してください

# docker compose のインストール
ここでは複数のコンテナ起動したり停止したりするためにdocker compose を使っていくので、まずはdocker compose をインストールします。
docker compose は複数のDocker コンテナからなるサービスの管理を簡単にするためのツールです。  
  
以下のページを開き、docker compose の最新版を確認します。  

[https://github.com/docker/compose/releases](https://github.com/docker/compose/releases "docker-compose")  

本記事執筆当時の最新版は1.14.0 なので、それをインストールします。

```
# curl -L https://github.com/docker/compose/releases/download/1.14.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
# chmod +x /usr/local/bin/docker-compose
```

# GitLab コンテナの起動
まず初めにGitLab のコンテナを起動し、Drone からGitLab のコンテンツを利用するためのOAuth API トークンを発行します。
以下のコマンドを実行し、GitLab コンテナを起動します。

```
# tar -Jxvf gitlabfs.tar.gz
// サンプルのソースコードが入っているファイルを展開します
...
# docker-compose up gitlab
// GitLab の起動に数分程度かかる可能性があります
```

Docker container が起動したら、Web ブラウザからGitLab へアクセスしてください。

```
http://gitlab.example.com
```

Sign in 画面が出てきたら、ユーザ名: `taro`、パスワード: `hogefuga` でログインしてください。
左上のメニューから`Projects` を選択し、サンプルプロジェクト(sample_node)が存在することを確認してください。

# Git Lab にOAuth アプリケーションの登録
Drone がGitLab のコンテンツをOAuth を使って取得できるように、GitLabに OAuth アプリケーションを登録します。
GitLab の画面右上のアイコンメニューから`Settings`を選択します。  

上部のメニューから`Applications` を選択し、以下のように値を入力し、`Save application` を押下します。

| 項目名          | 値    |
| --------------- | ----- |
| Name            | Drone |
| Redirect URI    | http://drone.example.com/authorize |

![OAuth アプリケーションの登録](https://github.com/TsutomuNakamura/KensyuForDocker/wiki/ContinuousDelivery/img/AddTheApplication_0000.png)  
  
アプリケーションを登録するとApplication Id とSecret が発行されるので忘れないようにメモを取っておいてください。  
![OAuth アプリケーションの登録](https://github.com/TsutomuNakamura/KensyuForDocker/wiki/ContinuousDelivery/img/AddTheApplication_0001.png)  
  
別ターミナルを開き、docker-compose.yml ファイルと同じディレクトリに.env ファイルを作成し、`DRONE_GITLAB_CLIENT` にApplication Id を、 `DRONE_GITLAB_SECRET` にSecret を記載してください。

```
DRONE_HOST=drone.example.com
DRONE_GITLAB_CLIENT=......    # <- GitLab から発行されたApplication Id
DRONE_GITLAB_SECRET=......   # <- GitLab から発行されたSecret
DRONE_GITLAB_URL=http://gitlab.example.com
DRONE_SECRET="secret"

IP_FOR_GITLAB=192.168.1.41
IP_FOR_DRONE=192.168.1.42
IP_FOR_BIND=192.168.1.43
```

記載が完了したら、docker-compose を実行しているターミナルにて`Ctrl + c` を押下してコンテナを終了(失敗した場合は`docker-compose stop`)させ、一旦コンテナを削除します。

```
// Ctrl + c
# docker-compose rm -f
```

# drone の構築
GitLab にOAuth アプリケーションの登録が完了したら、次はdrone を構築していきます。使用するdrone のDocker イメージは現在の最新である0.7 系を使っていきます。

```
# docker-compose up
// 上記のコマンドを実行することで、docker-compose.yml に記載されているすべてのコンテナ(GitLab, drone, Bind) が起動します。
```

全部のコンテナの起動が完了したら、drone にアクセスします。

```
http://drone.example.com
```

Login のリンクをクリックすると、リダイレクトされGitLab のOAuth 認証画面へ遷移するので、`taro/hogefuga` で認証を行ってください。
もし同じブラウザの別のタブでGitLab にログインしていた場合、セッションが保持されているのでユーザ名とパスワードの入力画面は省略されます。  
  
OAuth の確認画面が出てきますので、問題なければ`Auth` ボタンを押下します。  
  
これをもって、drone とGitLab の連携は完了です。
次は実際にプロジェクトのビルドをしていきます。

# プロジェクトのビルド
GitLab でリポジトリにソースコードのpush が発生したときに、自動的にテストを実行して結果を通知してくれるよう、ちょっとした設定を行っていきます。
今回はmocha で単体テスト自動化されたサンプルのnodejs プロジェクトを用意したので、それを使って継続的デリバリの1 歩を体験してみましょう。  
  
サンプルプロジェクトをclone します。

```
# cd ~
# git clone http://gitlab.example.com/taro/sample_node.git
# cd sample_node
# ls -l
-rw-rw-r-- 1 ...... index.js
-rw-rw-r-- 1 ...... package.json
.......
```

Drone でGitLab へのpush を契機にテストを自動的に走らせるにはプロジェクトのroot に`.drone.yml` ファイルを作成し、そこにDrone で実行するテストコマンドを定義します。
今回はmocha を使ってテスト自動化をするので以下のような記載になります。

```
pipeline:
  build:
    image: node:6
    commands:
      - npm install
      - npm test
```

上記ファイルを作成したらmaster ブランチにcommit, push してみましょう。

```
# git add .
# git commit -m ".drone.yml を作成し、nodejs のテスト自動化定義を追加"
# git push origin master
Username for 'http://gitlab.example.com': taro     # <- "taro"
Password for 'http://taro@gitlab.example.com':     # <- "hogefuga"
```

push が完了したらDrone のWeb 画面右上メニューからDashboard を開いてください。
ビルドとテストが自動的に走り始めていることが確認できるはずです。  
  
しばらくするとテスト結果がレポートされますが…テスト失敗です（　＾ω＾）
簡単な割り算をするプログラムですが、想定と違う結果になってしまっています。
プログラム本体はindex.js になりますので、そちらを編集してテストをパスするように修正してください。

index.js が修正が完了したらそれをまたcommit, push してください。

```
# git add .
# git commit -m "index.js に割り算の処理を追加"
# git push origin master
Username for 'http://gitlab.example.com': taro     # <- "taro"
Password for 'http://taro@gitlab.example.com':     # <- "hogefuga"
```

もう一度テストが走り、直した結果、ビルドとテストをパスすることができました！  
  
以降、開発用のgit ブランチを作成してテストケースの作成とプログラムの作成を続けていき、master ブランチにマージしてcommit, push していく…という継続的デリバリ(今回実施したレベルでは継続的インテグレーション)のサイクルを回していくことになります。
あなたのプロジェクトがうまく回りますように…Good luck!

# 参考
- Installation Overview
    - http://docs.drone.io/installation/

