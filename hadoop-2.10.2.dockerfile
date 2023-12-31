FROM ubuntu:bionic

WORKDIR /root

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

#####
# Disable suggests/recommends
#####
RUN echo APT::Install-Recommends "0"\; > /etc/apt/apt.conf.d/10disableextras
RUN echo APT::Install-Suggests "0"\; >>  /etc/apt/apt.conf.d/10disableextras

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_TERSE true

RUN apt-get -q update \
    && apt-get -q install -y --no-install-recommends \
        apt-utils \
        bzip2 \
        clang \
        curl \
        libsnappy-dev \
        libcurl4-openssl-dev \
        locales \
        rsync \
        sudo  \
    && apt-get clean

RUN locale-gen en_US.UTF-8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

#######
# OpenJDK 8
#######
# hadolint ignore=DL3008
RUN apt-get -q update \
    && apt-get -q install -y --no-install-recommends openjdk-8-jdk \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

ADD ./hadoop-2.10.2.tar.gz /usr/local/

WORKDIR /

ENV HADOOP_HOME /usr/local/hadoop-2.10.2
ENV PATH "${PATH}:$HADOOP_HOME/bin"