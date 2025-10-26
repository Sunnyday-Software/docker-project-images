ARG DOCKERHUB_USERNAME
ARG BASH_CHECKSUM
ARG PLATFORM_TAG
ARG IMAGE_FULL_NAME="noname"
ARG BASE_IMAGE=${DOCKERHUB_USERNAME}/bash:${BASH_CHECKSUM}-${PLATFORM_TAG}

FROM ${BASE_IMAGE}

ARG PLATFORM_TAG
# Versions and environment
ARG DEBIAN_FRONTEND=noninteractive
ARG NODE_VERSION=24.x
ARG NODE_ENV=production

ENV DEBIAN_FRONTEND=${DEBIAN_FRONTEND}
ENV NODE_ENV=${NODE_ENV}

USER root

# Image metadata
RUN echo "IMAGE_FULL_NAME=${IMAGE_FULL_NAME}" > /etc/image-info

RUN set -eux \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_VERSION nodistro main" | tee /etc/apt/sources.list.d/nodesource.list

# Install prerequisites, OpenJDK and Maven
RUN set -eux \
    && apt-get update -y \
    && apt-get install -y --no-install-recommends \
       build-essential \
       git \
       gnupg \
       ca-certificates \
       openjdk-17-jdk \
       maven \
       nodejs \
    && apt-get clean \
    && apt-get purge -y --auto-remove \
    && rm -rf /var/lib/apt/lists/*

# Switch back to unprivileged user provided by base image
USER bashuser
WORKDIR /workdir

ENV PLATFORM_TAG=${PLATFORM_TAG}

# Helpful defaults
ENV JAVA_HOME="/usr/lib/jvm/java-17-openjdk-${PLATFORM_TAG}"
ENV MAVEN_CONFIG=/home/bashuser/.m2
ENV PATH="/home/bashuser/.local/bin:${PATH}"

# Default entrypoint inherited from base image
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["bash", "-lc", "java -version && mvn -v && node --version && npm --version"]
