FROM ubuntu:22.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y update && apt-get install -y software-properties-common \
&& add-apt-repository ppa:deadsnakes/ppa && apt-get install -y build-essential python3-dev wget python3-distutils gcc && \
    rm -rf /var/lib/apt/lists/*

# create a non-root user
ARG USER_ID=1000
RUN useradd -m --no-log-init --system  --uid ${USER_ID} appuser -g sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER appuser
WORKDIR /home/appuser

ENV PATH="/home/appuser/.local/bin:${PATH}"
RUN wget https://bootstrap.pypa.io/pip/get-pip.py && \
    python3 get-pip.py --user && \
    rm get-pip.py

COPY ./requirements.txt .

RUN pip install -r requirements.txt


ENTRYPOINT [ "/bin/bash" ]