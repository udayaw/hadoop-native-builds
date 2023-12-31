#Source: https://raw.githubusercontent.com/apache/hadoop/branch-2.10.2/dev-support/docker/Dockerfile

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# hadoop-build-env.dockerfile for installing the necessary dependencies for building Hadoop.
# See BUILDING.txt.

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

######
# Install common dependencies from packages. Versions here are either
# sufficient or irrelevant.
#
# WARNING: DO NOT PUT JAVA APPS HERE! Otherwise they will install default
# Ubuntu Java.  See Java section below!
######
# hadolint ignore=DL3008
RUN apt-get -q update \
    && apt-get -q install -y --no-install-recommends \
        apt-utils \
        bats \
        build-essential \
        bzip2 \
        clang \
        cmake \
        curl \
        doxygen \
        fuse \
        g++ \
        gcc \
        git \
        gnupg-agent \
        libbz2-dev \
        libcurl4-openssl-dev \
        libfuse-dev \
        libprotobuf-dev \
        libprotoc-dev \
        libsasl2-dev \
        libsnappy-dev \
        libssl-dev \
        libsnappy-dev \
        libtool \
        libzstd1-dev \
        locales \
        make \
        pinentry-curses \
        pkg-config \
        python3 \
        python3-pip \
        python3-pkg-resources \
        python3-setuptools \
        python3-wheel \
        rsync \
        shellcheck \
        software-properties-common \
        sudo \
        zlib1g-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'
ENV PYTHONIOENCODING=utf-8

#######
# OpenJDK 8
#######
# hadolint ignore=DL3008
RUN apt-get -q update \
    && apt-get -q install -y --no-install-recommends openjdk-8-jdk \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

#######
# OpenJDK 7
#######
RUN curl -L -s -S https://cdn.azul.com/zulu/bin/zulu7.38.0.11-ca-jdk7.0.262-linux_amd64.deb \
      -o /opt/jdk7.deb \
    && apt-get -q install -y --no-install-recommends /opt/jdk7.deb \
    && rm -rf /opt/jdk7.deb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

######
# Install Google Protobuf 2.5.0 (3.0.0 ships with Bionic)
######
# hadolint ignore=DL3003
RUN mkdir -p /opt/protobuf-src \
    && curl -L -s -S \
      https://github.com/google/protobuf/releases/download/v2.5.0/protobuf-2.5.0.tar.gz \
      -o /opt/protobuf.tar.gz \
    && tar xzf /opt/protobuf.tar.gz --strip-components 1 -C /opt/protobuf-src \
    && cd /opt/protobuf-src \
    && ./configure --prefix=/opt/protobuf \
    && make install \
    && cd /root \
    && rm -rf /opt/protobuf-src
ENV PROTOBUF_HOME /opt/protobuf
ENV PATH "${PATH}:/opt/protobuf/bin"

######
# Install Apache Maven 3.6.0 (3.6.0 ships with Bionic)
######
# hadolint ignore=DL3008
RUN apt-get -q update \
    && apt-get -q install -y --no-install-recommends maven \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
ENV MAVEN_HOME /usr
# JAVA_HOME must be set in Maven >= 3.5.0 (MNG-6003)
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

#######
# Install SpotBugs 4.2.2
#######
RUN mkdir -p /opt/spotbugs \
    && curl -L -s -S https://github.com/spotbugs/spotbugs/releases/download/4.2.2/spotbugs-4.2.2.tgz \
      -o /opt/spotbugs.tgz \
    && tar xzf /opt/spotbugs.tgz --strip-components 1 -C /opt/spotbugs \
    && chmod +x /opt/spotbugs/bin/*
ENV SPOTBUGS_HOME /opt/spotbugs

####
# Install pylint and python-dateutil
####
RUN pip3 install pylint==2.6.0 python-dateutil==2.8.1

###
# Install hadolint
####
RUN curl -L -s -S \
        https://github.com/hadolint/hadolint/releases/download/v1.11.1/hadolint-Linux-x86_64 \
        -o /bin/hadolint \
   && chmod a+rx /bin/hadolint \
   && shasum -a 512 /bin/hadolint | \
        awk '$1!="734e37c1f6619cbbd86b9b249e69c9af8ee1ea87a2b1ff71dccda412e9dac35e63425225a95d71572091a3f0a11e9a04c2fc25d9e91b840530c26af32b9891ca" {exit(1)}'

###
# Avoid out of memory errors in builds
###
ENV MAVEN_OPTS -Xms256m -Xmx2048m -XX:MaxPermSize=512m -Dhttps.protocols=TLSv1.2 -Dhttps.cipherSuites=TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256


###
# Everything past this point is either not needed for testing or breaks Yetus.
# So tell Yetus not to read the rest of the file:
# YETUS CUT HERE
###

# Hugo static website generator (for new hadoop site and Ozone docs)
RUN curl -L -o hugo.deb https://github.com/gohugoio/hugo/releases/download/v0.30.2/hugo_0.30.2_Linux-64bit.deb \
    && dpkg --install hugo.deb \
    && rm hugo.deb


RUN git clone https://github.com/apache/hadoop

WORKDIR /root/hadoop

RUN git checkout branch-2.10.2 \
    && mvn package -q -Pdist,native -DskipTests -Dtar -Drequire.snappy \
    && cp -r hadoop-dist/target/hadoop-2.10.2 /usr/local \