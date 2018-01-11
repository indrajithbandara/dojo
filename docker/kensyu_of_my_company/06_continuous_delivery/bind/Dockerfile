# docker build -t "tsutomu/bind" .
# docker run --name bind -d tsutomu/bind

FROM ubuntu:16.04
LABEL maintainer tsutomu

RUN apt-get update
RUN apt-get install -y wget

RUN wget -q https://www.ubuntulinux.jp/ubuntu-ja-archive-keyring.gpg -O- | apt-key add -
RUN wget -q https://www.ubuntulinux.jp/ubuntu-jp-ppa-keyring.gpg -O- | apt-key add -
RUN wget https://www.ubuntulinux.jp/sources.list.d/xenial.list -O /etc/apt/sources.list.d/ubuntu-ja.list
RUN apt-get update

RUN apt-get -y install bind9 bind9utils

ENTRYPOINT /usr/sbin/named -f -u bind

