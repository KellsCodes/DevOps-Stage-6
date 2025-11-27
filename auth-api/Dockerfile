# Stage 1 - Build the Go application

FROM golang:1.21-alpine AS builder

RUN apk add --no-cache git

WORKDIR /app

COPY go.mod go.sum ./

RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o auth-api .

# Stage 2 - Create a minimal image to run the application

FROM alpine:latest

RUN adduser -D appuser

WORKDIR /app

COPY --from=builder /app/auth-api .

EXPOSE 8000

# Use a non-root user to run the application
USER appuser

CMD ["./auth-api"]