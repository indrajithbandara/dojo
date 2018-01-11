# よく使うオプションの紹介(-v|--volume, -p|--publish, -l|--link について)
Docker でよく使う基本的なオプションとして`-v|--volume`, `-p|--publish`, `-l|--link` オプションを紹介します。
これらのオプションを使うことでDocker コンテナを運用していく上で、便利な機能を利用することができるようになります。
簡単な説明としては以下の通りです。

| オプション        | 説明    |
| ------------------ | ----- |
| -v\|--volume     | ホスト側の指定されたディレクトリやファイルをコンテナの指定されたディレクトリ、ファイルにマウントします |
| -p\|--publish | コンテナ上のインタフェース(IPアドレス、ポーお番号)をホスト側のインタフェースにバインドし、外部へ公開するためのオプション |
| -l\|--link | Docker コンテナ内のネットワークで、コンテナが他のコンテナを名前解決できるようにします。複数コンテナで連携してシステムを構築するようなときに使われます |

これらのオプションを実際に使って便利さを体験してみるために、今回はMeidawiki アプリケーションサーバとそのデータを保管するSQL データベースをコンテナで起動して運用、データのバックアップからリストアまでの手順を実際にやっていきましょう。

# 構成概要及びDocker ネットワークについて
今回構築するDocker コンテナの構成としては以下のようにMediawiki(wiki) とdb コンテナを構築します。
wiki コンテナはdb コンテナとlink し、db へ書き込みや参照を行うようにします。  
  
またDocker は標準で以下の図のようにDocker ホストマシン上に独自なNetwork 構成を持つため、wiki が外部のクライントと通信をする場合、wiki コンテナはDocker ホスト側のIP とポートにバインドしてIP とポート番号をDocker ホストのそれに置換して外部クライアントと通信をする必要があります(NAT)。

```
* docker が持つNetwork の概要

+------------------------------------------------------+
| Docker network(172.17.0.0/16)                        |
|                                                      |
|     +-------------+ link     +-------------+         |
|     | wiki        |----------| db          |         |
|     | 172.17.x.x  |          | 172.17.y.y  |         |
|     +-------------+          +-------------+         |
|          |                                           |
|------ docker0 (172.17.0.1) --------------------------|
|          |                                           |
+------- eth0 (192.168.1.z) ---------------------------+
           |
  LAN(192.168.1.0/24)
           |
         (公開)
```

# db コンテナの構築
今回はMySQL 互換のmariadb のイメージを使って構築します。
今回使うmariadb は以下のオフィシャルイメージです。

[mariadb イメージ(https://hub.docker.com/_/mariadb/)](https://hub.docker.com/_/mariadb/ "mariadb")  
  
mariadb コンテナの起動は簡単！`docker run` コマンドを実行するだけで環境も含めて構築完了です。

```
# docker run --name mariadb -e MYSQL_ROOT_PASSWORD=secret -d mariadb
// MYSQL_ROOT_PASSWORD 変数にmariadb のroot ユーザのパスワードを入力

# docker ps
// mariadb コンテナが起動していることが確認できます
```

# wiki コンテナの構築
現状、Mediawiki のオフィシャルイメージは存在しません としてsimplyintricate 氏のmediawiki イメージを借用します。
 
[simplyintricate 氏の mediawiki イメージ(https://hub.docker.com/r/simplyintricate/mediawiki/)](https://hub.docker.com/r/simplyintricate/mediawiki/ "mediawiki")  

このコンテナの起動も`docker run` コマンドを実行することで簡単に起動することができます。
通常Mediawiki をLinux にインストールしようとすると、Linux のディストリビューションは何にするか、Web サーバはApache かnginx か、高速化するためのキャッシュはPHP APC キャッシュを使うかmemcached を使うか……といったことを決定して一つ一つ構築していかなければなりませんが、Docker を使うことでそんな手間から開放されるんです!  
  
実際のコンテナ起動手順としては以下のようになります。
mediawiki のデーバのバックアップを考慮して`/var/docker/wiki` というディレクトリを作り、コンテナの所定ディレクトリにマウントさせます。
こうすることでコンテナ上でmediawiki が作成したり書き込んだデータがホストOS 側の`/var/docker/wiki` ディレクトリいかにも格納されるようになり、コンテナを削除しても永続的にホストOS 側にデータが残るようになります。  
(# 実際にこれで本番運用する場合はホストOS 側の/var/docker/wiki 配下のデータを更に他のディスクに保管する等の対応は忘れずに実施してください)

```
# mkdir -p /var/docker/wiki
# docker run --name mediawiki --link mariadb:db -p 8080:80 -d simplyintricate/mediawiki
```

Web ブラウザを開き、以下のURL を指定してアクセスします。

```
http://localhost:8080

// Virtual Box などでLinux を起動してその上でDocker を起動している場合は、localhost の所にホストOS のLinux のIP or ホストを指定するようにしてください。
// また、Linux OS ホスト側のFirewall などでリクエストがブロックされていないかなども注意してください
```

画面の指示に従い設定作業を進めていきます(説明は割愛)。
データベースの設定画面まで進んだらデータベースのホスト名に`db(mediawiki コンテナを起動するときに--link で指定した名前)` 、データベースのパスワードに`secret(mariadb コンテナ起動時に指定したもの)` を指定してください。  
  
![Docker Hub でnode イメージの検索](https://github.com/TsutomuNakamura/KensyuForDocker/wiki/CreateMediawiki/img/SettingMediawiki_0002.png)  
  
以降、画面の指示に従ってインストール作業を進めていってください。
最後にLocalSettings.php がダウンロードされるので、それをDocker コンテナ上の/usr/share/nginx/html ディレクトリへ転送してください。
  
![Docker Hub でnode イメージの検索](https://github.com/TsutomuNakamura/KensyuForDocker/wiki/CreateMediawiki/img/SettingMediawiki_0003.png)  

Docker のホスト側からコンテナ側にデータをコピーする場合は`docker cp` コマンドを使います。

```
# docker cp LocalSettings.php mediawiki:/usr/share/nginx/html/LocalSettings.php
```

ファイルのコピーが完了したら、再度Web ブラウザでwiki のURL へアクセスしてみてください。

```
http://localhost:8080
```

![Docker Hub でnode イメージの検索](https://github.com/TsutomuNakamura/KensyuForDocker/wiki/CreateMediawiki/img/SettingMediawiki_0004.png)  

おめでとうございます！！上記のようにMediawiki のトップ画面が出てくれば構築成功です。
実際にwiki に記事を書き込んだりして内容が反映されることも確認してみてください。  
  
これであなたのナレッジや妄想を好き放題まとめる環境ができました。
次はこの大切な情報をたくさん保存することになるであろうMediawiki のデータのバックアップについて説明していきます。

# wiki 環境のバックアップ
wiki のデータをホストOS 側や別ディスクに保存するために取り出す必要があります。
今回構築したwiki 環境では、バックアップの対象としてwiki コンテナとdb コンテナのデータがあります。  
wiki コンテナのバックアップ対象としては主にアップロードした画像やファイル類、インストールしたwiki のプラグインなどがあり、db コンテナのバックアップ対象としてはmariadb のデータ(wiki の編集したテキストや履歴情報等)があります。  
また、これらのバックアップ作業を実施する前に、ユーザからのリクエストは受け付けないよう設定を事前に済ませておくようにしてください。  
  
まずはdb のバックアップを取得していきます。
mariadb のバックアップを取得する方法としては公式に`mysqldump` コマンドがあるので、それを利用して取得するようにします。
コンテナ環境上のmysqldump コマンドを実行するには`docker exec` コマンドを使用します。

```
# mkdir -p /var/docker/backup/wiki
# cd /var/docker/backup/wiki

# docker exec -i mariadb mysqldump --single-transaction --skip-lock-tables \
        -u root --password=secret --default-character-set=binary --databases my_wiki > /var/docker/backup/wiki/mysql.dump


```

次に、wiki コンテナ上のデータのバックアップを取得します。

```
# cd /var/docker/backup/wiki
# docker cp mediawiki:/usr/share/nginx/html/LocalSettings.php .
# docker cp mediawiki:/usr/share/nginx/html/images .
# docker cp mediawiki:/usr/share/nginx/html/extensions .
```

以上でバックアップは完了です。

# wiki 環境のリストア
では次に、バックアップからデータをリストアする手順について見ていきましょう。
まずはハードウェア的な障害が発生したことを想定して、wiki コンテナとdb コンテナを削除しましょう。

```
# docker stop mediawiki mariadb
# docker rm mediawiki mariadb
```

それでは、ここからリストア手順を実施していきます。  
  
リストアする手順としては、wiki コンテナとdb コンテナを再度作成し、データを復旧していきます。  
db コンテナについてはmysql コマンドでデータをDB にインポートし、wiki コンテナについては`--volume` オプションを使ってホストOS 側にあるバックアップデータをDocker コンテナ側にマウントさせて読み込ませる形で復旧していきます。

```
# docker run --name mariadb -e MYSQL_ROOT_PASSWORD=secret -d mariadb
# docker exec -i mariadb /usr/bin/mysql -u root --password=secret < /var/docker/backup/wiki/mysql.dump

# docker run --name mediawiki --link mariadb:db -p 8080:80 \
    -v /var/docker/backup/wiki/LocalSettings.php:/usr/share/nginx/html/LocalSettings.php:ro \
    -v /var/docker/backup/wiki/images:/usr/share/nginx/html/images \
    -v /var/docker/backup/wiki/extensions:/tmp/extensions \
    -d simplyintricate/mediawiki
```

以上でデータの復旧は完了です。
先ほどと同様にhttp://localhost:8080 へアクセスして、データが復旧できたことを確認してください。
