FROM ekozan/ruby:latest

MAINTAINER Ekozan

RUN apk --update add ca-certificates ruby-dev build-base curl-dev \
  && rm -rf /var/cache/apk/*

ENV FLUENTD_VERSION 0.12.16
RUN gem update --system \
  && gem install fluentd -v ${FLUENTD_VERSION} \
  && gem install fluent-plugin-kubernetes_metadata_filter \
                fluent-plugin-forest \
                fluent-plugin-elasticsearch \
                fluent-plugin-docker-format \
                fluent-plugin-diskusage

RUN mkdir -p /etc/fluent/
COPY docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
