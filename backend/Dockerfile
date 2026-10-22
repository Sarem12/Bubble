# Build Stage
FROM golang:1.22-alpine AS builder
WORKDIR /app

# Download dependencies first to leverage Docker layer caching
COPY go.mod go.sum ./
RUN go mod download

# Copy source code and build a lightweight binary
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o main ./cmd/api

# Final Stage (Tiny production image)
FROM alpine:latest
WORKDIR /app
COPY --from=builder /app/main .

EXPOSE 3000
CMD ["./main"]