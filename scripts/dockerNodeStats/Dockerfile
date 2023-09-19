FROM itisfoundation/ci-provisioned-ubuntu:0.4.0 as base


COPY requirements.txt /requirements.txt

RUN --mount=type=cache,mode=0755,target=/root/.cache/pip \
  pip install --upgrade pip \
  && pip install -r /requirements.txt \
  && pip freeze

COPY main.py /dockerNodeStats/main.py

RUN mkdir /outputs

WORKDIR /outputs

ENTRYPOINT ["python3","/dockerNodeStats/main.py"]
