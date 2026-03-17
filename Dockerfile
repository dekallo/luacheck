# Standalone luacheck container - no external image dependencies
FROM alpine:3.23

RUN apk add --no-cache luacheck curl

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /workspace

ENTRYPOINT ["/entrypoint.sh"]
