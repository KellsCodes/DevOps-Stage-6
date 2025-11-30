# Stage 1: Build the application

FROM node:12-buster AS builder

WORKDIR /app

RUN sed -i 's|deb.debian.org|archive.debian.org|g' /etc/apt/sources.list \
    && sed -i 's|security.debian.org|archive.debian.org|g' /etc/apt/sources.list \
    && sed -i '/buster-updates/d' /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y python2 make g++ \
    # Only create python symlink if it does NOT exist
    && if [ ! -f /usr/bin/python ]; then ln -s /usr/bin/python2 /usr/bin/python; fi

COPY package.json package-lock.json ./

RUN npm install

COPY . .

RUN npm run build

# Stage 2: Serve the application with Nginx

FROM nginx:alpine

RUN rm -rf /usr/share/nginx/html/*

COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
