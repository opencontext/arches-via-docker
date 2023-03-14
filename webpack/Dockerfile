FROM alpine:3.16

RUN apk update && \
    apk add --no-cache docker-cli docker-cli-compose

RUN apk add --no-cache --upgrade bash

RUN mkdir -p /action_dir
COPY webpack_entrypoint.sh /action_dir/
RUN chmod +x /action_dir/webpack_entrypoint.sh

WORKDIR /action_dir
CMD ["./webpack_entrypoint.sh"]