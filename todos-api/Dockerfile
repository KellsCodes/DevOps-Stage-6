# Stage 1 - Build stage
FROM node:18-alpine AS build

WORKDIR /app

COPY package.json ./

RUN npm install --production

COPY . .

# Stage 2 - Production stage
FROM node:18-alpine

WORKDIR /app

COPY --from=build /app /app

EXPOSE 9000

CMD ["npm", "start"]