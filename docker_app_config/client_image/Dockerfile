FROM alpine:3.3
MAINTAINER Johannes M. Scheuermann <joh.scheuer@gmail.com>

RUN apk --no-cache add curl
ADD https://github.com/kelseyhightower/confd/releases/download/v0.11.0/confd-0.11.0-linux-amd64 /usr/bin/confd
RUN chmod +x /usr/bin/confd
COPY start_up.sh /usr/bin/start_up.sh

CMD /usr/bin/start_up.sh
