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

# Healthcheck
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags="-s -w" \
    -o /out/healthcheck ./cmd/healthcheck

FROM gcr.io/distroless/static-debian12 AS app

COPY --from=builder /out/app /app
COPY --from=builder /out/healthcheck /healthcheck

USER nonroot:nonroot

ENTRYPOINT ["/app"]


FROM gcr.io/distroless/static-debian12 AS migrate

COPY --from=builder /out/migrate /migrate
COPY --from=builder /app/migrations /migrations

USER nonroot:nonroot

ENTRYPOINT ["/migrate"]