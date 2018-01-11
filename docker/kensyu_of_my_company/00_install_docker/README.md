# Docker のインストールについて
Docker はWindows, Mac, Linux といったあらゆるOS ディストリビューションにインストールすることができるようになっています。
ただ基本的にDocker はLinux カーネル上で動作するものなので、Linux 以外のディストリビューションにインストールする場合は、
Microsoft hyper-v やVirtual Box といったhypervisor 環境上にLinux 相当な環境を構築し、その上にDocker がインストールされる形になります。  
  
ここでは具体的な手順は公式ページに譲歩することにし、各OS ごとに概要だけ説明します。

# Windows へのインストールについて
Windows へインストールする場合、Docker for Windows とDocker tool box の選択肢があります。

## Docker for Windows
Docker for Windows はMicrosoft hyper-v を使ってDocker をインストールします。
Microsoft hyper-v を有効にするとVirtual Box が使えなくなるのでその点注意して実施してください。

## Docker tool box
Virtual Box をインストールしてその上にLinux とDocker 環境をインストールする方式。
Docker for Windows が動かない場合、もしくはVirtual Box が動かなくなると困る場合はこちらを選択すると良いでしょう。

# Mac へのインストールについて
TODO:

# Linux へのインストール
Docker の良さが最大限に生かされる組み合わせです。
有名所のディストリビューション、例えばUbuntu、Debian、CentOS、Fedora といったディストリビューションについては公式(英語)にもまとめられています。
自宅の余っているPC 等を使用してLinux を直接インストールしている場合はこちらの選択肢をおすすめします。

# インストールページ
[Install Docker(https://docs.docker.com/engine/installation/)](https://docs.docker.com/engine/installation/ "Install Docker")  

# 今回のハンズオンの説明資料の環境について
今回のハンズオンの資料はLinux にDocker を入れて検証して作成されています。
もし動かない場合はVirtual Box にUbuntu などのディストリビューションを入れ、そこにDocker をインストール・検証してみてください。
