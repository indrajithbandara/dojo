FROM node:5
RUN npm -g install redis
ENV NODE_PATH /usr/local/lib/node_modules
EXPOSE 8888

ENTRYPOINT ["node", "app.js"]

