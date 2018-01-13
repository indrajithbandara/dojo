FROM debian:jessie

RUN apt-get update
RUN apt-get -y install nodejs
RUN ln -s /usr/bin/nodejs /usr/bin/node

COPY nodeprog /opt/nodeprog
EXPOSE 80

ENTRYPOINT ["node", "/opt/nodeprog/test.js"]

