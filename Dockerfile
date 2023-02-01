FROM alpine:3.17.1

RUN apk --no-cache add jq curl

COPY rename.sh /bin/rename.sh
COPY root.cron /var/spool/cron/crontabs/root

CMD ["crond", "-l", "2", "-f"]

HEALTHCHECK \
  --interval=30s \
  --timeout=30s \
  --start-period=5s \
  --retries=3 \
  CMD pidof crond || exit 1
