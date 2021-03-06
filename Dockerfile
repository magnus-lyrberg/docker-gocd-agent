FROM centos:7
MAINTAINER karel.bemelmans@unibet.com

RUN set -x \
  && yum update -y \
  && yum install -y epel-release \
  && yum install -y \
    device-mapper-libs \
    git \
    java-1.8.0-openjdk \
    python2-pip \
    subversion \
    unzip \
  && pip install awscli

# Add go user and group
RUN groupadd -g 500 go \
  && useradd -u 500 -g 500 -d /var/lib/go-agent --no-create-home -s /bin/bash -G go go

# Install GoCD Server from zip file
ARG GO_MAJOR_VERSION=17.10.0
ARG GO_BUILD_VERSION=5380
ARG GO_VERSION="${GO_MAJOR_VERSION}-${GO_BUILD_VERSION}"
ARG GOCD_SHA256=a5e50f7a5f0375d8bf13183fd2d534fc56c9b2915020a0cd69829c1f5e4d08e6

RUN curl -L --silent https://download.gocd.org/binaries/${GO_VERSION}/generic/go-agent-${GO_VERSION}.zip \
       -o /tmp/go-agent.zip \
  && echo "${GOCD_SHA256}  /tmp/go-agent.zip" | sha256sum -c - \
  && unzip /tmp/go-agent.zip -d /usr/local \
  && ln -s /usr/local/go-agent-${GO_MAJOR_VERSION} /usr/local/go-agent \
  && chown -R go:go /usr/local/go-agent-${GO_MAJOR_VERSION} \
  && rm /tmp/go-agent.zip

RUN mkdir -p /etc/default \
  && cp /usr/local/go-agent-${GO_MAJOR_VERSION}/go-agent.default /etc/default/go-agent \
  && chown go:go /etc/default /etc/default/go-agent \
  && sed -i -e "s|DAEMON=Y|DAEMON=N|" /etc/default/go-agent

RUN mkdir /etc/go && chown go:go /etc/go \
  && mkdir /var/lib/go-agent && chown go:go /var/lib/go-agent \
  && mkdir /var/log/go-agent && chown go:go /var/log/go-agent

# log everything to console
RUN sed -i -e 's|log4j.rootCategory=.*|log4j.rootCategory=INFO,CONSOLE\r\nlog4j.appender.CONSOLE=org.apache.log4j.ConsoleAppender\r\nlog4j.appender.CONSOLE.layout=org.apache.log4j.PatternLayout\r\nlog4j.appender.CONSOLE.layout.ConversionPattern=%d{ISO8601} [%-9t] %-5p %-16c{4}:%L %x- %m%n\r\n|' /usr/local/go-agent/config/*.properties

# add the entrypoint config and run it when we start the container
COPY ./docker-entrypoint.sh /
RUN chmod 500 /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
