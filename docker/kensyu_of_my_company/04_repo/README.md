# リポジトリにイメージをpush する
前回の課題でDockerfile を使ったイメージの作成について説明しました。
そのイメージはリポジトリにpush してチーム内のメンバや世界中の人々に配布することができるようになります。  
方法としてはDocker Hub にpush する方法と独自にDocker リポジトリを建ててそこにpush する方法があります。

# Docker Hub を利用する
Docker Inc によって運営されているDocker リポジトリにpush する方法について実際にやっていくことにします。  

[Docker Hub(https://hub.docker.com/)](https://hub.docker.com/ "Docker Hub")  

## Docker Hub にイメージをpush する
前回の課題で作成したtsutomu/nodetest をDockerhub へpush してみましょう。
説明は価値愛しますが事前にDocker Hub にユーザを作成しておいてください。  
  
Docker Hub アカウントを作成したら、コマンドラインから`docker login` コマンドを使ってDocker Hub にログインします。

```
# docker login
Login with your Docker ID to push and pull images from Docker Hub. If you don't have a Docker ID, head over to https://hub.docker.com to create one.
Username: tsutomu    # <- ユーザ名
Password:            # <- パスワード
Login Succeeded
```

push する前に、必要に応じて`docker tag` コマンドでtag をつけてください。
なおタグをつけないでpush した場合、自動的に`latest` というタグがつけられてDocker Hub へpush されます。

```
# docker tag tsutomu/nodetest:v1.0
```

タグ付けも完了したら`docker push` コマンドでイメージをpush します。

```
# docker push tsutomu/nodetest:v1.0
```

push が成功したらDocker Hub のアカウントのページに表示されるようになりますので確認してください。

![Docker Hub にイメージをpush](https://github.com/TsutomuNakamura/KensyuForDocker/wiki/FirstContainer/img/FirstContainer_0001.png)

## Docker Hub からイメージをpull する
Docker Hub にイメージをpush できたら、次にそのイメージがDocker Hub からpull できるか確認してみましょう。
pull してくる領域を作成するためにまずはローカルにあるコンテナとイメージを削除しておきます。

```
# docker rm nodetest
# docker rmi tsutomu/nodetest
```

コンテナとイメージを削除したら、docker run コマンドでtsutomu/nodetest イメージをpull してコンテナを起動させてみましょう。

```
# docker run --name nodetest -p 8080:80 -d tsutomu/nodetest
Unable to find image 'tsutomu/nodetest:latest' locally        # <- イメージがないので、ダウンロードが開始する
latest: Pulling from tsutomu/nodetest
bd97b43c27e3: Already exists 
6960dc1aba18: Already exists 
2b61829b0db5: Already exists 
1f88dc826b14: Already exists 
73b3859b1e43: Already exists 
8f605fe2ea3d: Pull complete 
93c280113f25: Pull complete 
......

# curl http://localhost:8080/?name=taro
Hello taro
```

成功です!

# 独自のDocker リポジトリを利用する
Docker Hub を使うことで世界中のユーザに自分のイメージを公開することができますが、一部のチームメンバーのみにイメージを公開したいといったことがあると思います。
そんな時はDocker のリポジトリを自分の組織内で建てて、イメージを管理すると良いでしょう。
Docker のリポジトリのイメージはregistry と呼ばれ、Docker registry が公式のイメージとしてDocker Hub で公開されています。
  
[registry(https://hub.docker.com/_/registry/)](https://hub.docker.com/_/registry/ "registry")  

Docker registry コンテナを起動します。

```
# docker run -d -p 5000:5000 --name registry registry:2
# docker ps
-> registry が起動していること
```

Docker registry にpush する時は、push するイメージにtag をつけて、tag にpush 先のロケーションも指定するようにします。
まずはtag づけするイメージを確認します。

```
# docker images
REPOSITORY                  TAG                 IMAGE ID            CREATED             SIZE
tsutomu/nodetest            latest              cd3f63353e49        42 minutes ago      458MB
```

registry にpush する用のtag は以下のようになります。

```
# docker tag tsutomu/nodetest localhost:5000/tsutomu/nodetest
// "localhost" という指定がありますが、これは後々pull するときも"localhost" と指定することになります。
// そのため、実際にチームなどで運用する場合は別にサーバを建てて、それぞれのチームメンバーが参照できる場所にpush するようにしてください
```

tag をつけたら、docker push でregistry へイメージをpush します。

```
# docker push localhost:5000/tsutomu/nodetest
```

push が完了したら、registry からイメージを検索してみましょう。

```
# curl -X GET http://localhost:5000/v2/_catalog
{"repositories":["tsutomu/nodetest"]}
```

すると上記のようにREST API により登録されているイメージのリストが返されるのが確認できると思います。

## TODO: docker search コマンドによる検索について
Docker registry 上のイメージは、おそらくdocker search コマンドを使って検索できるようになっているはずですが…現状以下のようにコマンドを実行してもregistry からイメージを検索できることはできません(情報求む)。

```
# docker search localhost:5000/tsutomu/nodetest
Error response from daemon: Unexpected status code 404
```

以下の記事によると`docker search` コマンドでできると情報がありますが、registry がv2 になってからまたできなくなっているのでしょうか…？

[How to search images from private 1.0 registry in docker?(stack overflow)](https://stackoverflow.com/questions/23733678/how-to-search-images-from-private-1-0-registry-in-docker "How to search images from private 1.0 registry in docker?(stack overflow)")  

# Docker registry からイメージをpull(run) する
Docker registry からイメージを取得するには、docker pull(or run) するときのイメージID にregistry のロケーションも指定するようにします。

```
# docker run --name nodetest -p 8080:80 -d localhost:5000/tsutomu/nodetest
```
