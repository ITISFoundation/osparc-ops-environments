FROM debian:bookworm-slim

ENV KUBECTL_VERSION=v1.30.0 \
    HELM_VERSION=v3.20.0 \
    HELMFILE_VERSION=v1.1.6

# git is necessary for `helm plugin install` (used by helmfile init)
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl \
        git \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSLo /usr/local/bin/kubectl \
        "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    && chmod +x /usr/local/bin/kubectl

RUN curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" \
    | tar xz --strip-components=1 -C /usr/local/bin linux-amd64/helm

RUN curl -fsSL "https://github.com/helmfile/helmfile/releases/download/${HELMFILE_VERSION}/helmfile_${HELMFILE_VERSION#v}_linux_amd64.tar.gz" \
    | tar xz -C /usr/local/bin helmfile

RUN curl -fsSL https://opencode.ai/v2/install | bash \
    && mv /root/.opencode/bin/opencode /usr/local/bin/opencode \
    && rm -rf /root/.opencode

# non-root user matching the typical Linux host's first user (UID/GID 1000)
RUN groupadd -g 1000 opencode && useradd -u 1000 -g 1000 -m -s /bin/bash opencode
USER opencode

# runs as opencode so plugins land in its helm data dir, not root's
RUN helmfile init --force

# pre-create mount targets so volumes inherit opencode ownership instead of root
RUN mkdir -p ~/.local/share/opencode ~/.config/opencode

WORKDIR /workspace

CMD ["opencode"]
