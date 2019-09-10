FROM alpine:latest
MAINTAINER Trurl McByte

RUN apk --no-cache -U add nextcloud-client

ADD https://dl.min.io/client/mc/release/linux-amd64/mc /usr/bin/minio

ADD startup.sh /startup.sh

CMD [ "/startup.sh" ]
