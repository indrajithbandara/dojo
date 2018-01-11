# コンテナを起動してみよう
Docker のインストールが完了したら、初めてのDocker コンテナを起動してみましょう。
Docker でコンテナを起動する場合、流れとしてはDocker イメージをローカルに取得し、そのイメージからコンテナを起動します。

今回はnode(nodejs) のイメージをローカルに取得し、コンテナの起動させてみましょう。
イメージを検索する際は、`docker search` コマンドを使う方法とDocker Hub のWeb にアクセスして検索する方法があります。

特に理由がないのであればDocker Hub から検索するほうが見やすいのでそちらをおすすめします。  
  
[Docker Hub(https://hub.docker.com/)](https://hub.docker.com/ "Docker Hub")  

Docker Hub のページを開いたら検索フォームから`node` を検索してみましょう。
すると一番上にOfficial イメージが出てくるはずです。

![Docker Hub でnode イメージの検索](https://github.com/TsutomuNakamura/KensyuForDocker/wiki/FirstContainer/img/FirstContainer_0001.png)

node のイメージをクリックするとイメージの詳細を確認することができます。

## 補足: official イメージについて
Docker のofficial イメージはDocker Inc によって管理されるイメージで、基本的なOS、プログラミング言語のようなベースとなるようなものがよくofficial イメージとなります。
official イメージはドキュメントが整備され、セキュリティパッチも管理されることが約束されているイメージです。  

一方で、Docker Hub には個人や組織で作成されたイメージも存在し、世界中の人に配布することができるようになっていますが、そのイメージの管理はその個人や組織に委ねられます。
そのため、official でないイメージを重要なシーンで利用する場合には、そのイメージがしっかりとメンテナンスされていることも確認するようにしましょう。

official なイメージとそうでないイメージを見分ける方法ですが、Docker Hub でイメージを検索したときに`<イメージ名>` とだけ出てくるイメージはofficial イメージです。
一方で`<ユーザ・組織名>/<イメージ名>` と出てくるイメージは非official なイメージとなります。

# node イメージの取得(pull)
ターミナルを開き、一番上のnode のofficial イメージをローカルに取得してみましょう。
イメージを取得する時は`docker pull` コマンドを実行します。

```
# docker pull node
...
```

イメージのダウンロードが完了したら、`docker images` コマンドでイメージを確認してみましょう。

```
# docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
node                latest              f3068bc71556        19 hours ago        667MB
```

初めてのイメージがpull できました！次にこのイメージからコンテナを起動してみましょう。

# コンテナの作成と起動(run)
コンテナを起動する場合は`docker run <イメージ名>` コマンドで起動します。
今回は標準入力の維持とpseudo-tty(疑似端末) を割り当てるために`-ti` というオプションも加えて実行します。

```
# docker run -ti node
>
```

すると、">" のプロンプトが表示されました。
nodejs がインタラクティブモードで起動している状態です。
このままJavaScript の文法で`console.log('Hello');` と入力してみましょう。

```
> console.log('Hello');
Hello
undefined    # <- これはconsole.log メソッドの戻り値が表示されている
```

プログラムが実行されました！
抜けるにはCtrl + D を押下し、node のプロセスを終了させます。
  
ホスト側のプロンプトに戻ったら、コンテナが作成されているので確認してみましょう。

```
# docker ps -a 
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS                     PORTS               NAMES
a09b42a40f5d        node                "node"              3 minutes ago       Exited (0) 3 minutes ago                       pedantic_sinoussi
```

すると、上記のようなコンテナが確認できました。
STATUS に`Exited (0) ......` と表示されており、コンテナが終了していることも確認できます。
LXC のような仮想化では、node のプロセス1 個が終了してもコンテナは終了しないのに対し、Docker ではこのように目的のプロセスが終了したら、原則コンテナも終了するようになっています。  
コンテナの名前についてですが、この例では`pedantic_sinoussi` となっていますが、自動的に作成されたものです。
コンテナ名を自分でつけたい場合は"docker run" したときに`--name` オプションを指定してつけるようにしてください。

## 自動的にイメージを取得(pull) する
今回は明示的に`docker pull` コマンドでイメージを取得してから`docker run` コマンドでコンテナ作成と起動をしましたが、`docker run` コマンド実行時に指定したイメージがローカルに存在しない場合は、自動的にイメージを検索してダウンロードされるようになっています。
なので、docker pull コマンドは省略することができます。

## イメージのタグ(バージョン)を指定して取得する
イメージには複数のタグ(バージョン)を持つものがあります。
今回使用したnode にも色々バージョンがあり、本記事執筆時点では最新版として8 系が存在しますが、これを明示的に6 系に変更したい時はコマンドでイメージを指定するときにタグ名も指定するようにしてください。

```
# docker run -ti node:6.11.0
```

なお、今までの説明のようにタグ名を省略した場合は、自動的に`latest` というタグのイメージが取得され、たいていは最新版のイメージが取得できるようになっています。  
  
イメージにどんなtag が存在するか確認するにはオフィシャルイメージであればDocker Hub のページにたいてい載っていますので確認してみましょう。
書かれていない場合はDocker registry API を叩いて確認してみましょう(もっと良い方法があれば情報求む…)。

```
# curl -L -s 'https://registry.hub.docker.com/v2/repositories/<username>/<imagename>/tags?page_size=1024'|jq '."results"[]["name"]'
// オフィシャルイメージの場合は<username> のところに"library" と入れてください

(例: node のtag 一覧を取得する)
# curl -L -s 'https://registry.hub.docker.com/v2/repositories/library/node/tags?page_size=1024'|jq '."results"[]["name"]'
Ref: https://stackoverflow.com/questions/28320134/how-to-list-all-tags-for-a-docker-image-on-a-remote-registry
```

## 非オフィシャルなイメージを取得する
イメージ名の前にユーザ名を指定するようにしてください。

```
# docker run tianon/true
```

# コンテナの起動
停止したコンテナを起動する場合は`docker start <コンテナ名>` コマンドを実行します。

```
# docker start pedantic_sinoussi
pedantic_sinoussi
```

起動中のコンテナを確認するには`docker ps` コマンドを使用します。。
起動中のコンテナを確認する場合は`-a` オプションは不要です。

```
# docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
a09b42a40f5d        node                "node"              10 minutes ago      Up 9 seconds                            pedantic_sinoussi
```

先程とは異なり、コンテナは起動していますが、これにアタッチする端末がない状態です。
この起動中のコンテナにアタッチして、先ほどと同様に`console.log('Hello');` と入力してみましょう。

```
# docker attach pedantic_sinoussi
> console.log('Hello');
Hello
undefined
```

先程と同様にJavaScript プログラムが実行できました！
このようにして一度停止したコンテナは`docker start` コマンドで再起動させることができます。

## コンテナ・イメージを削除する
もうnode でいっぱい遊んだし環境いらないや……。
不要になったコンテナを削除するには`docker rm <コンテナ名>` コマンドでコンテナを削除することができます。

```
# docker rm pedantic_sinoussi
pedantic_sinoussi
# docker ps -a
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
## コンテナがなくなったことが確認できます
```

この削除してしまったコンテナはローカルにnode イメージがある限り、また`docker run` コマンドを使って高速で復元することができます。
また、ディスク容量をもっと節約したい等の理由でイメージを削除することもできます。  
イメージを削除する時は`docker rmi <イメージ名>` コマンドを使います。

```
# docker rmi node
```

イメージをローカルから削除すると、先程と同様な環境がもう作れなくなってしまう…ということはりません！
また`docker pull (docker run)` コマンドを実行すればDocker Hub からnode イメージがローカルにダウンロードされ、コンテナが起動することになります。
ただ、イメージのダウンロードに少し時間がかかるだけです。  

自分マシンを新しく買い替えてしまって…という場合でも、もちろんDocker をインストールして`docker pull (docker run)` とすれば先程と同様の環境が簡単に復元することができるようになるのです。
このようにDocker ではあらゆるマシンやチーム内のメンバに同様の環境を簡単に、そして素早く提供することができるようになり「私のマシン上では動いているんだ！」問題を未然に防ぐことができるようになるわけです。


## その場限りのコンテナを作成する(--rm)
コンテナが停止したら毎回削除するのは面倒という時は、ephemeral (その場限りのコンテナ)コンテナを作成することもできます。
ephemeral なコンテナを作成したい時は`--rm` オプションをつけてコンテナを作成します。

```
# docker run --rm -ti node
> console.log('Hello');
Hello
undefined

# docker ps -a
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
```

当然ですがコンテナ内にデータを作成してしまったりした場合、コンテナ停止と同時にそのデータも削除されてしまうので注意してください。


## 標準入力からnode のプログラムを送る
ここまでの説明ではnode をインタラクティブモードで起動してきましたが、Docker では標準入力からデータをコンテナに送り込むこともできます。
例えば、手元にnode のプログラムがファイルとしてあり、それを標準入力でコンテナに送り実行させるといったこともできます。

```
# cat << __EOF__ > program.js
console.log('Hello');
__EOF__

# ls program.js
program.js

# cat program.js
console.log('Hello');

# docker run --rm -i node:6.11.0 < program.js
Hello
```
