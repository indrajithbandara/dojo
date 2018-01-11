# Dockerfile を使う
Dockerfile を使うことでユーザのオリジナルのイメージを自動的に作成することができます。
別の言い方をするのであれば、Dockerfile はユーザの独自イメージを作成するためのレシピとなるものです。
Dockerfile を作成することで、イメージのビルドが自動化され、例えば誤ってイメージを削除してしまった場合でもDockerfile が残っていれば簡単に同じイメージを作り直すことができるようになります。  
  
また、作成されたイメージはDockerhub やチーム内で建てたDocker リポジトリにpush することで他のチームメンバーや世界中の人達にたいして簡単にイメージを配布することができるようになります。

# Dockerfile のサンプル
Dockerfile でイメージを作成する場合、他のイメージをベースに自分用のイメージを作成するのがセオリーです。
今回はubuntu コンテナにnodejs をインストールし、簡単なnodejs プログラムを実行するイメージを作成してみます。  
  
今回作成するDockerfile は以下のような内容です。

```
FROM ubuntu:16.04
LABEL maintainer tsutomu

RUN apt-get update
RUN apt-get install -y wget

RUN wget -q https://www.ubuntulinux.jp/ubuntu-ja-archive-keyring.gpg -O- | apt-key add -
RUN wget -q https://www.ubuntulinux.jp/ubuntu-jp-ppa-keyring.gpg -O- | apt-key add -
RUN wget https://www.ubuntulinux.jp/sources.list.d/xenial.list -O /etc/apt/sources.list.d/ubuntu-ja.list
RUN apt-get update

RUN apt-get install -y nodejs npm
RUN update-alternatives --install /usr/bin/node node /usr/bin/nodejs 10
COPY ./app /root/app
WORKDIR /root
RUN npm install express

ENTRYPOINT NODE_PATH=/root/node_modules node /root/app/start.js
```

上記のDockerfile はubuntu にnodejs をインストールし、ホスト側にあるapp ディレクトリ(nodejs のアプリがあるディレクトリ)をコピーし、コンテナを起動したときにapp ディレクトリ内のstart.js プログラムを実行するといった内容のものになります。  
  
なお、ここで使われているDockerfile の命令としては以下のとおりです。
より詳細な説明については公式ページを確認してください。

https://docs.docker.com/engine/reference/builder/

- FROM ubuntu:16.04
    - イメージを作成するベースとなるイメージ。本例ではubuntu 16.04
- LABEL maintainer tsutomu
    - メンテナの名前
- RUN <command>
    - 実行するコマンド。RUN コマンドに成功の度にcommit され、base イメージや前回のRUN コマンドで作成されたイメージの上に積み重なっていく
- COPY ./app /root/app
    - ホスト上のファイルやディレクトリをコンテナ上にコピーする
- ENTRYPOINT
    - コンテナ実行時に実行されるコマンド(CMD もあるが若干違う)

start.js の内容は次のようになっています。

```
var app = require('express')();

app.get('/', function(req, res) {
    res.send("Hello " + req.query.name + "\n");
});
app.listen(80);
```

それではイメージをbuild してみましょう！  
イメージをbuild するときはDockerfile があるディレクトリへ移動して以下のようにコマンドを実行します。

```
# cd /path/to/dockerfile
# docker build -t "tsutomu/nodetest" .
// 上記のdocker build コマンドの書式は"docker build -t <user name>/<image name> ." となるので、適宜変更してください
......
```

build に成功するとimage が作成されますので確認してみましょう。

```
# docker images
REPOSITORY                  TAG                 IMAGE ID            CREATED              SIZE
tsutomu/nodetest            latest              6f291f5f836a        About a minute ago   205MB
```

## 補足; イメージを作成する他の方法
Dockerfile でビルドでなくとも、とある状態のDocker コンテナに対して`docker commit` を使うことでもイメージは作成することができます。  
  
ただ、チームやプロジェクトで作業する場合などイメージがどのようにできているかレシピ(設計書)を残すという観点でDockerfile を使って行う癖をつけておくのがいいかもしれません。
またDockerfile としてイメージのレシピを残しておくことで、チーム他メンバーが誤りや改善案を進言してくれることがあるかもしれません。  
  
もし、Dockerfile にbuild で使われる正しいコマンドを一発で書くのが難しい場合、テスト用のコンテナを走らせてからそこで直接コマンドを一つずつ実行していき、成功したコマンドだけ都度Dockerfile に記載していくスタイルをとるのもよいかもしれません。
そのほかの手段としては、docker build のデバッグ方法を勉強するのもアリです(ここでは割愛)。

# コンテナを起動する
それでは先程作成したイメージからコンテナを起動してみましょう。
コマンドは以下のようになります。

```
# docker run --name nodetest -p 8080:80 -d tsutomu/nodetest
```

コンテナが起動したら、curl コマンドで動作を確認してみましょう。

```
# curl http://localhost:8080/?name=taro
Hello taro
```

上記のようにレスポンスが取得できれば成功です。

