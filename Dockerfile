FROM alpine:latest
MAINTAINER Trurl McByte

RUN apk --no-cache -U add curl nextcloud-client \
    && mkdir -p /usr/local/bin \
    && curl -o /tmp/rclone-current-linux-amd64.zip -L https://downloads.rclone.org/rclone-current-linux-amd64.zip \
    && busybox unzip -o /tmp/rclone-current-linux-amd64.zip -d /tmp \
    && rm -f /tmp/rclone-current-linux-amd64.zip \
    && mv -f /tmp/rclone-v*-linux-amd64/rclone /usr/local/bin/ \
    && rm -rf /tmp/rclone-v*-linux-amd64
    && chmod +x /usr/local/bin/rclone

ADD startup.sh /startup.sh

CMD [ "/startup.sh" ]
