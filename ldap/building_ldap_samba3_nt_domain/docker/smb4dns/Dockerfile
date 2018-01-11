FROM debian:jessie

# Debian jessie's repository in Japan
RUN echo "deb http://ftp.jp.debian.org/debian/ jessie main contrib non-free" > /etc/apt/sources.list

RUN apt-get update

# BIND::Config::Parser
RUN apt-get -y install bind9 libbind-config-parser-perl libbind-confparser-perl



