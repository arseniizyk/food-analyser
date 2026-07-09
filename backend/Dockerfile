FROM golang:1.26-alpine AS builder

WORKDIR /app

RUN apk add --no-cache ca-certificates

COPY go.mod go.sum ./

RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

COPY . .

# App
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags="-s -w" \
    -o /out/app ./cmd/app

# Migrate
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags="-s -w" \
    -o /out/migrate ./cmd/migrate

FROM gcr.io/distroless/static-debian12 AS app

COPY --from=builder /out/app /app

USER nonroot:nonroot

ENTRYPOINT ["/app"]


FROM gcr.io/distroless/static-debian12 AS migrate

COPY --from=builder /out/migrate /migrate

USER nonroot:nonroot

ENTRYPOINT ["/migrate"]