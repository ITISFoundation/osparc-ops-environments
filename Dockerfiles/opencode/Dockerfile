FROM debian:bookworm-slim

# set automatically by BuildKit (amd64, arm64, ...)
ARG TARGETARCH

ENV KUBECTL_VERSION=v1.30.0 \
    HELM_VERSION=v3.20.0 \
    HELMFILE_VERSION=v1.1.6

# git is necessary for `helm plugin install` (used by helmfile init)
# git is also useful for opencode
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl \
        git \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSLo /usr/local/bin/kubectl \
        "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl" \
    && chmod +x /usr/local/bin/kubectl

RUN curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-${TARGETARCH}.tar.gz" \
    | tar xz --strip-components=1 -C /usr/local/bin "linux-${TARGETARCH}/helm"

RUN curl -fsSL "https://github.com/helmfile/helmfile/releases/download/${HELMFILE_VERSION}/helmfile_${HELMFILE_VERSION#v}_linux_${TARGETARCH}.tar.gz" \
    | tar xz -C /usr/local/bin helmfile

# TODO: pin version, unpinned install is not reproducible
RUN curl -fsSL https://opencode.ai/v2/install | bash \
    && mv /root/.opencode/bin/opencode /usr/local/bin/opencode \
    && rm -rf /root/.opencode

# host user's UID/GID, passed via compose build args (default 1000)
ARG USER_UID=1000
ARG USER_GID=1000
# -o allows non-unique IDs (e.g. macOS GID 20 collides with Debian's 'dialout')
RUN groupadd -o -g "${USER_GID}" opencode \
    && useradd -o -u "${USER_UID}" -g "${USER_GID}" -m -s /bin/bash opencode
USER opencode

# runs as opencode so plugins land in its helm data dir, not root's
RUN helmfile init --force

# pre-create mount targets so volumes inherit opencode ownership instead of root
RUN mkdir -p ~/.local/share/opencode ~/.config/opencode

WORKDIR /workspace

CMD ["opencode"]
