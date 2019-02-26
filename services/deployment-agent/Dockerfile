# TODO: this is still not finished!!
FROM python:3.6-alpine as base

LABEL maintainer=sanderegg

#  USAGE:
#     cd sercices/deployment-agent
#     docker build -f Dockerfile -t deployment-agent:prod --target production ../../
#     docker run deployment-agent:prod
#
#  REQUIRED: context expected at ``osparc-simcore/`` folder because we need access to osparc-simcore/packages

# non-root user 'scu'
ARG DOCKER_GID_ARG=1001
RUN adduser -D -u 8004 scu &&\
    addgroup -g $DOCKER_GID_ARG docker

RUN apk add --no-cache \
      su-exec

ENV HOME /home/scu
ENV PIP  /home/scu/.venv/bin/pip3

EXPOSE 8888

# ----------------------------------------------------------------
# will start to run after interval every interval. fails after timeout. fail do not count if during start-period. will do # retries
HEALTHCHECK --interval=30s --timeout=60s --start-period=60s --retries=3 \
      CMD python3 /home/scu/docker/healthcheck_curl_host.py 'http://localhost:8888/v0/'

# -------------------------- Build stage -------------------
#
# + /home/scu/              $HOME
#    + packages
#        ...
#    + services/deployment-agent
#       + src
#       + tests
#
#
# TODO: straight copying python packages bring unnecessary files (e.g. __pycache__) -> dockerignore!
#       could copy and then python setup.py install OR git clone into the container.
#       This applies for both
#
FROM base as build

RUN apk add --no-cache \
      gcc \
      libc-dev \
      git \
      docker \
      make

RUN python3 -m venv $HOME/.venv &&\
    $PIP install --upgrade \
      pip \
      wheel \
      setuptools \
      docker-compose &&\
      rm -rf /tmp/.pipcache

WORKDIR /home/scu

# install base 3rd party packages to accelerate runtime installs
COPY --chown=scu:scu requirements/base.txt requirements-base.txt
RUN $PIP install -r requirements-base.txt &&\
      rm -rf /tmp/.pipcache

# --------------------------Development stage -------------------
FROM build as development

ARG HOST_GID_ARG=1000

# install test 3rd party packages to accelerate runtime installs
COPY --chown=scu:scu tests/requirements.txt requirements-tests.txt
RUN $PIP install -r requirements-tests.txt &&\
      rm -rf /tmp/.pipcache

# in dev mode we give access to `scu` to host's mapped volumes
RUN addgroup -g $HOST_GID_ARG hgrp &&\
    addgroup scu hgrp && \
    chown -R scu:scu $HOME/.venv

VOLUME /home/scu/services/deployment-agent/
VOLUME /home/scu/docker

WORKDIR /home/scu
ENV RUN_DOCKER_ENGINE_ROOT=0
ENV DEBUG 1
ENTRYPOINT [ "/bin/sh", "docker/entrypoint.sh" ]
CMD ["/bin/sh", "docker/boot.sh"]


# --------------------------Production multi-stage -------------------
#FROM build as build-production
FROM build as production

ENV SIMCORE_WEB_CONFIG production

# server
COPY --chown=scu:scu . $HOME/deployment-agent
COPY --chown=scu:scu docker $HOME/docker

WORKDIR /home/scu/deployment-agent
RUN $PIP install -r requirements/prod.txt &&\
    $PIP list &&\
    rm -rf /tmp/.pipcache

#------------------- Cleanup ---------------------------------------
WORKDIR /home/scu

RUN rm -rf $HOME/deployment-agent &&\
    rm requirements-base.txt

ENV RUN_DOCKER_ENGINE_ROOT=0
ENV DEBUG 0
ENTRYPOINT [ "/bin/sh", "docker/entrypoint.sh" ]
CMD ["/bin/sh", "docker/boot.sh"]
