# docker run -d -p 6565:6565 image-server
ARG BASE_REGISTRY=docker.io
ARG BASE_IMAGE=nvidia/cuda
ARG BASE_TAG=12.5.0-runtime-ubuntu22.04

FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG} as builder

LABEL maintainer="semoss@semoss.org"

COPY semoss_requirements.txt /tmp/
COPY cfgai_requirements.txt /tmp/
COPY gpu_requirements.txt /tmp/

RUN arch=$(uname -m) \
    && if [[ $arch == arm* ]] || [[ $arch = aarch64 ]]; then apt-get -y install libhdf5-dev; fi

# TODO: Remove unnecessary packages
RUN apt-get update \
    && apt-get install -y python3-pip curl tesseract-ocr \
    && apt-get -y autoremove \
    && /usr/bin/python3 -m pip install --upgrade -r /tmp/semoss_requirements.txt \
    && /usr/bin/python3 -m pip install --upgrade -r /tmp/cfgai_requirements.txt \
    && /usr/bin/python3 -m pip install --upgrade -r /tmp/gpu_requirements.txt \
    && apt-get purge -y --auto-remove \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /root/.cache

# TODO: Update references to image-gen
RUN cd /opt && \
    apt update && apt install -y wget unzip \
    && wget https://github.com/SEMOSS/Semoss/archive/refs/heads/image-gen.zip \
    && unzip image-gen.zip \
    && rm image-gen.zip \
    && mv Semoss-image-gen semosshome

EXPOSE 6565

WORKDIR /opt/semosshome/py

CMD ["python3", "gaas_tcp_socket_server.py", "--port", "6565", "--max_count", "5", "--py_folder", "/opt/semosshome/py", "--insight_folder", "/path/to/insight", "--prefix", "some_prefix", "--timeout", "10", "--start", "True"]
