FROM alpine:3.16

RUN apk update && \
    apk add --no-cache docker-cli docker-cli-compose

RUN apk add --no-cache --upgrade bash

RUN mkdir -p /workdir
COPY webpack_entrypoint.sh /workdir/
RUN chmod +x /workdir/webpack_entrypoint.sh

WORKDIR /workdir
CMD ["./webpack_entrypoint.sh"]