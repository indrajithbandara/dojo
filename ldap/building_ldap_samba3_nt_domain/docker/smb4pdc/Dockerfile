FROM debian:jessie

# Debian jessie's repository in Japan
RUN echo "deb http://ftp.jp.debian.org/debian/ jessie main contrib non-free" > /etc/apt/sources.list

RUN apt-get update
RUN apt-get install -y apt-transport-https
RUN apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
RUN echo "deb https://apt.dockerproject.org/repo debian-jessie main" > /etc/apt/sources.list.d/docker.list
RUN apt-get update
RUN apt-get install -y docker-engine

COPY child /root/child

RUN cd /root/child && chmod u+x BuildChild.sh

EXPOSE 53 88 135 137 138 139 389 464 3268 5353

ENTRYPOINT ["/root/child/BuildChild.sh"]

