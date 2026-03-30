FROM golang:1.26-alpine3.23 as build

WORKDIR /go/src/github.com/harness/harness
RUN apk add --no-cache --purge --clean-protected -u git ca-certificates tzdata \
  && git clone --branch v2.28.1 https://github.com/harness/harness.git . \
  && go build -v -a -tags "oss nolimit" -ldflags "-extldflags \"-static\"" -o release/linux/drone-server /go/src/github.com/harness/harness/cmd/drone-server

FROM alpine:3.23

ENV GODEBUG netdns=go \
    XDG_CACHE_HOME /data \
    DRONE_DATABASE_DRIVER sqlite3 \
    DRONE_DATABASE_DATASOURCE /data/database.sqlite \
    DRONE_RUNNER_OS=linux \
    DRONE_RUNNER_ARCH=amd64 \
    DRONE_SERVER_PORT=:80 \
    DRONE_SERVER_HOST=localhost \
    DRONE_DATADOG_ENABLED=false

COPY --from=build /go/src/github.com/harness/harness/release/linux/drone-server /bin/
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /usr/share/zoneinfo /usr/share/zoneinfo

EXPOSE 80 443
VOLUME /data
ENTRYPOINT ["/bin/drone-server"]
