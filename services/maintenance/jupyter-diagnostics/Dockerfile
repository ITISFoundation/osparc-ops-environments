#FROM nbgallery/jupyter-alpine:7.8.4
FROM jupyter/base-notebook:python-3.7.3 AS base

USER root

RUN apt-get update && apt-get -yq dist-upgrade \
 && apt-get install -yq --no-install-recommends \
    git \
    curl \
    iputils-ping \
    python3-pip \
 && rm -rf /var/lib/apt/lists/*


# FIXME: https://github.com/ITISFoundation/osparc-ops/issues/24
#COPY --chown=jovyan:users scripts/healthcheck_curl_host.py $HOME/scripts/healthcheck_curl_host.py
#HEALTHCHECK --interval=30s \
#            --timeout=120s \
#            --start-period=30s \
#            --retries=3 \
#            CMD ["python3", "${HOME}/scripts/healthcheck_curl_host.py", "http://localhost:8888"]

USER $NB_UID


# enable single-user server
RUN unset JUPYTERHUB_API_TOKEN

COPY --chown=jovyan:users bin/*.sh /usr/local/bin/
COPY --chown=jovyan:users requirements.txt /tmp/

RUN pip3 --no-cache install --upgrade pip wheel setuptools && \
    pip3 --no-cache install -r /tmp/requirements.txt &&\
    rm /tmp/requirements.txt

COPY --chown=jovyan:users work/ $HOME/work

WORKDIR $HOME/work
RUN jupyter trust notebooks/*; mkdir data


USER root
ENTRYPOINT ["tini", "-g", "/bin/bash", "--", "entrypoint.sh"]
CMD [ "boot.sh" ]
