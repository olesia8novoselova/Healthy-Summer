FROM golang:1.24-alpine AS build

RUN apk add --no-cache git tzdata
WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o main ./cmd/server

FROM alpine:latest AS production
WORKDIR /app

# runtime deps
RUN apk add --no-cache tzdata ca-certificates

COPY --from=build /app/main .
COPY --from=build /app/migrations ./migrations

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --quiet --spider http://localhost:8080/health || exit 1

CMD ["./main"]
