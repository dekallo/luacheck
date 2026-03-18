FROM alpine:3.23

RUN apk add --no-cache luacheck curl lua5.1

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /workspace

ENTRYPOINT ["/entrypoint.sh"]
