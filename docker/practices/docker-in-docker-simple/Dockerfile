FROM debian:jessie

RUN apt-get update
RUN apt-get install -y apt-transport-https
RUN apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
RUN echo "deb https://apt.dockerproject.org/repo debian-jessie main" > /etc/apt/sources.list.d/docker.list
RUN apt-get update
RUN apt-get install -y docker-engine
RUN docker daemon &

COPY child /root/child

RUN cd /root/child && chmod u+x BuildChild.sh
EXPOSE 80

ENTRYPOINT ["/root/child/BuildChild.sh"]

