# docker build -t "tsutomu/nodetest" .
# docker run --name nodetest -p 8080:80 -d tsutomu/nodetest

FROM ubuntu:16.04
LABEL maintainer tsutomu

RUN apt-get update
RUN apt-get install -y wget=1.17.1-1ubuntu1.2

RUN wget -q https://www.ubuntulinux.jp/ubuntu-ja-archive-keyring.gpg -O- | apt-key add -
RUN wget -q https://www.ubuntulinux.jp/ubuntu-jp-ppa-keyring.gpg -O- | apt-key add -
RUN wget https://www.ubuntulinux.jp/sources.list.d/xenial.list -O /etc/apt/sources.list.d/ubuntu-ja.list
RUN apt-get update

RUN apt-get install -y nodejs=4.2.6~dfsg-1ubuntu4.1 npm=3.5.2-0ubuntu4
RUN update-alternatives --install /usr/bin/node node /usr/bin/nodejs 10
COPY ./app /root/app
WORKDIR /root
RUN npm install express@4.15.3

ENTRYPOINT NODE_PATH=/root/node_modules node /root/app/start.js

