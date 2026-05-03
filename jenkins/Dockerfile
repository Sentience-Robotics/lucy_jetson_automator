# Tier-0 controller image: tracks Jenkins LTS via Docker Hub moving tag (pull/build regularly for core fixes).
# plugins.txt lists plugin IDs only; jenkins-plugin-cli installs latest compatible builds at image build time.
FROM jenkins/jenkins:lts-jdk21

USER root

ARG TF_VERSION=1.9.8
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    git \
    unzip \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    openssh-client \
  && rm -rf /var/lib/apt/lists/*

RUN ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') \
  && curl -fsSL "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_${ARCH}.zip" -o /tmp/tf.zip \
  && unzip /tmp/tf.zip -d /usr/local/bin \
  && rm /tmp/tf.zip

RUN pip3 install --break-system-packages --no-cache-dir \
    ansible-core==2.17.14 \
    python-openstackclient==7.3.0 \
    openstacksdk==3.3.0

COPY ansible/requirements.yml /tmp/ansible-requirements.yml
RUN ansible-galaxy collection install -r /tmp/ansible-requirements.yml -p /usr/share/ansible/collections

COPY jenkins/dsl/*.groovy /usr/share/jenkins/ref/jobdsl/

USER jenkins

COPY jenkins/plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --verbose --plugin-file /usr/share/jenkins/ref/plugins.txt
