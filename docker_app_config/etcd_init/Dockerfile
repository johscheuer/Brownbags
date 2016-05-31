FROM alpine:3.3
MAINTAINER Johannes M. Scheuermann <joh.scheuer@gmail.com>

RUN apk --no-cache add curl
COPY provision_etcd.sh /usr/bin/provision_etcd.sh

CMD /usr/bin/provision_etcd.sh
