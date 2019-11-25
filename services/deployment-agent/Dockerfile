FROM python:3.6-alpine as base

LABEL maintainer=sanderegg

#  USAGE:
#     cd sercices/deployment-agent
#     docker build -f Dockerfile -t deployment-agent:prod --target production ../../
#     docker run deployment-agent:prod
#
#  REQUIRED: context expected at ``osparc-simcore/`` folder because we need access to osparc-simcore/packages

# simcore-user uid=8004(scu) gid=8004(scu) groups=8004(scu)
RUN adduser -D -u 8004 -s /bin/sh -h /home/scu scu

RUN apk add --no-cache \
      su-exec

ENV PATH "/home/scu/.local/bin:$PATH"

# All SC_ variables are customized
ENV SC_PIP pip3 --no-cache-dir
ENV SC_BUILD_TARGET base

EXPOSE 8888

RUN apk add --no-cache \
      docker \
      make \
      bash \
      gettext \
      git

RUN apk add --no-cache --virtual .build-deps \
      gcc \
      libc-dev \
      openssl-dev \
      libffi-dev &&\
      $SC_PIP install --upgrade \
      pip \
      wheel \
      setuptools \
      docker-compose &&\
      apk --purge del .build-deps
# -------------------------- Build stage -------------------
# Installs build/package management tools and third party dependencies
#
# + /build             WORKDIR
#

FROM base as build

ENV SC_BUILD_TARGET build

# install base 3rd party packages to accelerate runtime installs
WORKDIR /build
COPY --chown=scu:scu requirements/_base.txt requirements-base.txt

RUN apk add --no-cache --virtual .build-deps \
      gcc \
      libc-dev \
      musl-dev \
      postgresql-dev &&\
      $SC_PIP install \
      -r requirements-base.txt && \
      apk --purge del .build-deps

# --------------------------Production stage -------------------
FROM build as production

ENV SC_BUILD_TARGET production
ENV SC_BOOT_MODE production

COPY --chown=scu:scu . /build/services/deployment-agent
WORKDIR /build/services/deployment-agent

RUN apk add --no-cache --virtual .build-deps \
      gcc \
      libc-dev &&\
      $SC_PIP install -r requirements/prod.txt &&\
      mkdir -p /home/scu/services/deployment-agent &&\
      chown scu:scu /home/scu/services/deployment-agent &&\
      mv /build/services/deployment-agent/docker /home/scu/services/deployment-agent/docker &&\
      rm -rf /build &&\
      apk --purge del .build-deps

WORKDIR /home/scu

HEALTHCHECK --interval=30s \
      --timeout=60s \
      --start-period=30s \
      --retries=3 \
      CMD python3 /home/scu/services/deployment-agent/docker/healthcheck.py 'http://localhost:8888/v0/'

ENTRYPOINT [ "/bin/sh", "services/deployment-agent/docker/entrypoint.sh" ]
CMD ["/bin/sh", "services/deployment-agent/docker/boot.sh"]


# --------------------------Development stage -------------------
FROM build as development

ENV SC_BUILD_TARGET development
ENV SC_BOOT_MODE development

# install test 3rd party packages to accelerate runtime installs
COPY --chown=scu:scu tests/requirements.txt requirements-tests.txt
RUN apk add --no-cache --virtual .build-deps \
      gcc \
      libc-dev &&\
      $SC_PIP install -r requirements-tests.txt

WORKDIR /devel
VOLUME /devel/services/deployment-agent/


ENTRYPOINT [ "/bin/sh", "services/deployment-agent/docker/entrypoint.sh" ]
CMD ["/bin/sh", "services/deployment-agent/docker/boot.sh"]
