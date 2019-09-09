FROM alpine:latest
MAINTAINER Trurl McByte

RUN apk --no-cache -U add nextcloud-client

ADD startup.sh /startup.sh

CMD [ "/startup.sh" ]
