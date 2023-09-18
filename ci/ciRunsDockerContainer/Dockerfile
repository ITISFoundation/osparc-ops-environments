ARG UBUNTU_VERSION="focal-20230412"
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
  software-properties-common \
  gnupg \
  apt-utils

RUN add-apt-repository ppa:mozillateam/ppa # add repo for firefox

COPY mozillateam.pref /etc/apt/preferences.d/mozillateam.pref

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  build-essential \
  curl \
  firefox=117.0.1+build2-0ubuntu0.20.04.1 \
  gettext-base \
  git \
  jq \
  make \
  openssl \
  openssh-client \
  python3-pip \
  python3.9-venv \
  python-is-python3 \
  sshpass \
  unzip \
  wget \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Install minio mc
RUN echo "------------------------------------------------------ minio/mc" \
  && curl https://dl.min.io/client/mc/release/linux-amd64/archive/mc.RELEASE.2022-10-01T07-56-14Z    --create-dirs   -o $HOME/minio-binaries/mc \
  && chmod +x $HOME/minio-binaries/mc \
  && export PATH=$PATH:$HOME/minio-binaries/

## ASSERT MC WORKS
RUN $HOME/minio-binaries/mc --help

# Install geckodriver
RUN echo "------------------------------------------------------ geckodriver" \
  && apt install wget -y \
  && wget https://github.com/mozilla/geckodriver/releases/download/v0.33.0/geckodriver-v0.33.0-linux64.tar.gz \
  && tar -xvzf geckodriver* \
  && chmod +x geckodriver \
  && mv geckodriver /usr/local/bin/

RUN pip install --no-cache-dir --upgrade \
  pip~=22.0  \
  wheel \
  setuptools \
  ansible==6.7.0

RUN echo "------------------------------------------------------ terraform" \
    && cd /tmp && wget https://releases.hashicorp.com/terraform/1.5.1/terraform_1.5.1_linux_amd64.zip \
    && unzip terraform_1.5.1_linux_amd64.zip  -d /usr/local/bin \
    && rm /tmp/terraform_1.5.1_linux_amd64.zip

WORKDIR /home/scu

CMD ["/bin/bash"]
