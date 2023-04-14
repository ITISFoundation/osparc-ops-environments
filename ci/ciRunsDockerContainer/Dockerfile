ARG UBUNTU_VERSION="jammy"
FROM ubuntu:${UBUNTU_VERSION} as base
#
LABEL maintainer=dkaiser

RUN set -eux && \
  apt-get update && \
  apt-get install -y gosu && \
  rm -rf /var/lib/apt/lists/* && \
  # verify that the binary works
  gosu nobody true

# simcore-user uid=8004(scu) gid=8004(scu) groups=8004(scu)
ENV SC_USER_ID=8004 \
  SC_USER_NAME=scu \
  SC_BUILD_TARGET=base \
  SC_BOOT_MODE=default

RUN adduser \
  --uid ${SC_USER_ID} \
  --disabled-password \
  --gecos "" \
  --shell /bin/sh \
  --home /home/${SC_USER_NAME} \
  ${SC_USER_NAME}


# Sets utf-8 encoding for Python et al
ENV LANG=C.UTF-8

# Turns off writing .pyc files; superfluous on an ephemeral container.
ENV PYTHONDONTWRITEBYTECODE=1 \
  VIRTUAL_ENV=/home/scu/.venv

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  apt-utils \
  build-essential \
  curl \
  gettext-base \
  gettext-base \
  git \
  gnupg \
  make \
  openssl \
  openssh-client \
  python3-pip \
  python3.10-venv \
  software-properties-common \
  unzip \
  wget \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Install minio mc
RUN curl https://dl.min.io/client/mc/release/linux-amd64/archive/mc.RELEASE.2022-10-01T07-56-14Z    --create-dirs   -o $HOME/minio-binaries/mc \
  && chmod +x $HOME/minio-binaries/mc \
  && export PATH=$PATH:$HOME/minio-binaries/

## ASSERT MC WORKS
RUN $HOME/minio-binaries/mc --help

RUN pip install --no-cache-dir --upgrade \
  pip~=22.0  \
  wheel \
  setuptools \
  ansible

RUN echo "------------------------------------------------------ terraform" \
    && cd /tmp && wget https://releases.hashicorp.com/terraform/1.4.4/terraform_1.4.4_linux_amd64.zip \
    && unzip terraform_1.4.4_linux_amd64.zip  -d /usr/local/bin \
    && rm /tmp/terraform_1.4.4_linux_amd64.zip

WORKDIR /home/scu

CMD ["/bin/bash"]
