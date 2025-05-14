FROM fluent/fluentd:v1.16.8-1.0

USER root

# Install dependencies and plugins
RUN apk add --no-cache --update --virtual .build-deps \
    sudo build-base ruby-dev curl \
 && sudo gem install fluent-plugin-grafana-loki \
 && sudo gem install fluent-plugin-gelf-best \
 && sudo gem install fluent-plugin-prometheus \
 && apk del .build-deps \
 && apk add --no-cache curl jq \
 && rm -rf /var/cache/apk/* \
 && rm -rf /tmp/* /var/tmp/* /usr/lib/ruby/gems/*/cache/*.gem

# Create directories with appropriate permissions
RUN mkdir -p /fluentd/buffer /fluentd/log \
    && chown -R fluent:fluent /fluentd/buffer /fluentd/log

# Health check
HEALTHCHECK --interval=30s --timeout=30s --retries=3 \
  CMD curl -s http://localhost:24220/api/plugins | jq -e '.plugins | length > 0' || exit 1

USER fluent

ENTRYPOINT ["fluentd", "-c", "/fluentd/etc/fluent.conf"]
