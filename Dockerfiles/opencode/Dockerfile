FROM debian:bookworm-slim

# set automatically by BuildKit (amd64, arm64, ...)
ARG TARGETARCH

ENV KUBECTL_VERSION=v1.30.0 \
    HELM_VERSION=v3.20.0 \
    HELMFILE_VERSION=v1.1.6 \
    KUBERNETES_MCP_SERVER_VERSION=0.0.67

# git is necessary for `helm plugin install` (used by helmfile init)
# git is also useful for opencode
# make is used in ./charts/Makefile
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl \
        git \
        make \
        nodejs npm \
    && rm -rf /var/lib/apt/lists/*

RUN npm install --global "kubernetes-mcp-server@${KUBERNETES_MCP_SERVER_VERSION}" \
    && npm cache clean --force

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

ARG USER_UID=1000
ARG USER_GID=1000
# -o allows non-unique IDs (e.g. macOS GID 20 collides with Debian's 'dialout')
RUN groupadd -o -g "${USER_GID}" opencode \
    && useradd -o -u "${USER_UID}" -g opencode -m -s /bin/bash opencode
USER opencode

# install helmfile pluging (e.g., helm-diff)
RUN helmfile init --force

# pre-create mount targets so volumes inherit opencode ownership instead of root
RUN mkdir -p ~/.local/share/opencode ~/.config/opencode

WORKDIR /workspace

CMD ["opencode"]
