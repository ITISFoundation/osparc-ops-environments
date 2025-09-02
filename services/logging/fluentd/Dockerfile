FROM fluent/fluentd:v1.16.9-debian-1.0

USER root

# Install dependencies and plugins using apt instead of apk
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ruby-dev \
    curl \
    jq \
 && gem install fluent-plugin-grafana-loki \
 && gem install fluent-plugin-gelf-best \
 && gem install fluent-plugin-prometheus \
 && apt-get purge -y --auto-remove build-essential ruby-dev \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /tmp/* /var/tmp/* /usr/lib/ruby/gems/*/cache/*.gem

# Create directories with appropriate permissions
RUN mkdir -p /fluentd/buffer /fluentd/log \
    && chown -R fluent:fluent /fluentd/buffer /fluentd/log

# Health check
HEALTHCHECK --interval=30s --timeout=30s --retries=3 \
  CMD curl -s http://localhost:24220/api/plugins | jq -e '.plugins | length > 0' || exit 1

USER fluent

ENTRYPOINT ["fluentd", "-c", "/fluentd/etc/fluent.conf"]
