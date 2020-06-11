ARG PYTHON_VERSION="3.6.10"
FROM python:${PYTHON_VERSION}-slim as base
#
#  USAGE:
#     cd sercices/deployment-agent
#     docker build -f Dockerfile -t deployment-agent:prod --target production ../../
#     docker run deployment-agent:prod
#
#  REQUIRED: context expected at ``osparc-simcore/`` folder because we need access to osparc-simcore/packages

LABEL maintainer=sanderegg

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
# Ensures that the python and pip executables used
# in the image will be those from our virtualenv.
ENV PATH="${VIRTUAL_ENV}/bin:$PATH"

EXPOSE 8888


# necessary tools for running deployment-agent
RUN apt-get update &&\
      apt-get install -y --no-install-recommends \
      docker \
      make \
      bash \
      gettext \
      git


# -------------------------- Build stage -------------------
# Installs build/package management tools and third party dependencies
#
# + /build             WORKDIR
#
FROM base as build

ENV SC_BUILD_TARGET=build

RUN apt-get update &&\
      apt-get install -y --no-install-recommends \
      build-essential


# NOTE: python virtualenv is used here such that installed packages may be moved to production image easily by copying the venv
RUN python -m venv "${VIRTUAL_ENV}"

ARG DOCKER_COMPOSE_VERSION="1.25.4"
RUN pip --no-cache-dir install --upgrade \
      pip~=20.0.2  \
      wheel \
      setuptools \
      docker-compose~=${DOCKER_COMPOSE_VERSION}

# All SC_ variables are customized
ENV SC_PIP pip3 --no-cache-dir
ENV SC_BUILD_TARGET base

COPY --chown=scu:scu . /build/services/deployment-agent
# install base 3rd party dependencies (NOTE: this speeds up devel mode)
RUN pip --no-cache-dir install -r /build/services/deployment-agent/requirements/_base.txt


# --------------------------Cache stage -------------------
# CI in master buils & pushes this target to speed-up image build
#
#  + /build
#    + services/sidecar [scu:scu] WORKDIR
#
FROM build as cache

WORKDIR /build/services/deployment-agent
ENV SC_BUILD_TARGET=cache
RUN pip --no-cache-dir install -r /build/services/deployment-agent/requirements/prod.txt

# --------------------------Production stage -------------------
# Final cleanup up to reduce image size and startup setup
# Runs as scu (non-root user)
#
#  + /home/scu     $HOME = WORKDIR
#    + services/sidecar [scu:scu]
#
FROM build as production

ENV SC_BUILD_TARGET=production \
      SC_BOOT_MODE=production
ENV PYTHONOPTIMIZE=TRUE

WORKDIR /home/scu

# bring installed package without build tools
COPY --from=cache --chown=scu:scu ${VIRTUAL_ENV} ${VIRTUAL_ENV}
# copy docker entrypoint and boot scripts
COPY --chown=scu:scu docker services/deployment-agent/docker

HEALTHCHECK --interval=30s \
      --timeout=60s \
      --start-period=30s \
      --retries=3 \
      CMD python3 /home/scu/services/deployment-agent/docker/healthcheck.py 'http://localhost:8888/v0/'

ENTRYPOINT [ "/bin/sh", "services/deployment-agent/docker/entrypoint.sh" ]
CMD ["/bin/sh", "services/deployment-agent/docker/boot.sh"]


# --------------------------Development stage -------------------
# Source code accessible in host but runs in container
# Runs as scu with same gid/uid as host
# Placed at the end to speed-up the build if images targeting production
#
#  + /devel         WORKDIR
#    + services  (mounted volume)
#
FROM build as development

ENV SC_BUILD_TARGET=development

WORKDIR /devel
RUN chown -R scu:scu "${VIRTUAL_ENV}"
ENTRYPOINT [ "/bin/sh", "services/deployment-agent/docker/entrypoint.sh" ]
CMD ["/bin/sh", "services/deployment-agent/docker/boot.sh"]
