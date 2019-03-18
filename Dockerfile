FROM benweet/stackedit-base

WORKDIR /opt/stackedit

COPY package*json /opt/stackedit/
COPY gulpfile.js /opt/stackedit/
RUN npm get registry
RUN npm config set registry http://registry.npm.taobao.org/
RUN yarn config set registry http://registry.npm.taobao.org/
RUN npm install --unsafe-perm \
  && npm cache clean --force
COPY . /opt/stackedit
ENV NODE_ENV production
RUN npm run build

EXPOSE 8080

CMD [ "node", "." ]
