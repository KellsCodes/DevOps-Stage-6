# Stage 1 - Build stage
FROM node:18-alpine AS build

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm install

COPY . .

# Stage 2 - Production stage
FROM node:18-alpine

WORKDIR /app

COPY --from=build /app /app

EXPOSE 8082

CMD ["npm", "start"]
