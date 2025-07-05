
ARG DOCKERHUB_USERNAME
ARG BASH_CHECKSUM
ARG PLATFORM_TAG

FROM ${DOCKERHUB_USERNAME}/bash:${BASH_CHECKSUM}-${PLATFORM_TAG}

ARG IMAGE_FULL_NAME
ARG NODE_VERSION=22.x
ARG DEBIAN_FRONTEND=noninteractive

USER root

RUN echo "IMAGE_FULL_NAME=${IMAGE_FULL_NAME}" > /etc/image-info

# Install Node.js
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    apt-utils \
    ca-certificates \
    curl \
    gnupg \
    build-essential \
    git

RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_VERSION nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get update -y

RUN apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy .bashrc.d scripts
COPY home/ /home/bashuser/
RUN find /home/bashuser -type f -name '*.sh' -exec dos2unix {} \; -exec chmod +x {} \; && \
    find /home/bashuser/.local/bin -type f -exec chmod +x {} \; && \
    chown bashuser:bashuser -R /home/bashuser

USER bashuser
WORKDIR /home/bashuser
ENV PATH="/home/bashuser/node_modules/.bin:${PATH}"

RUN npm install


# Set working directory
WORKDIR /workdir

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Default command
CMD ["node", "--version"]
