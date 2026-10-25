# Builds CLIProxyAPI from the official upstream repository at a pinned commit (no vendored source).
FROM golang:1.26-bookworm AS builder
ARG CLIPROXY_REPO=https://github.com/router-for-me/CLIProxyAPI
ARG CLIPROXY_VERSION=v8.0.42
ARG CLIPROXY_COMMIT=bc0643405a1d0adf77dd0f109972ac3313d66397
RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates build-essential && rm -rf /var/lib/apt/lists/*
WORKDIR /src
RUN git clone --filter=blob:none "$CLIPROXY_REPO" . && git checkout --detach "$CLIPROXY_COMMIT" \
 && test "$(git rev-parse HEAD)" = "$CLIPROXY_COMMIT"
RUN go mod download && CGO_ENABLED=1 go build -buildvcs=false \
    -ldflags="-s -w -X 'main.Version=${CLIPROXY_VERSION}' -X 'main.Commit=${CLIPROXY_COMMIT}'" \
    -o /out/cli-proxy-api ./cmd/server/

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates tzdata curl && rm -rf /var/lib/apt/lists/*
COPY --from=builder /out/cli-proxy-api /app/cli-proxy-api
WORKDIR /app
ENV TZ=Europe/Warsaw
EXPOSE 8317
CMD ["/app/cli-proxy-api", "-config", "/app/config.yaml"]
