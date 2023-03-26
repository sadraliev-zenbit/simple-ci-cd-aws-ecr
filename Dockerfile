# Build Stage 1
# This build created a staging docker image
#
FROM node:16-alpine AS appbuild
WORKDIR /usr/src/app
COPY package.json ./
RUN npm install
COPY . .
RUN npm run build

# Build Stage 2
# This build takes the production build from staging build
#
FROM node:16-alpine
WORKDIR /usr/src/app
COPY package.json ./
RUN npm install
COPY --from=appbuild /usr/src/app/dist ./dist
EXPOSE 3000
CMD ["node", "dist/main"]
