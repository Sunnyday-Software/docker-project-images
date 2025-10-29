
ARG DOCKERHUB_USERNAME
ARG BASH_CHECKSUM
ARG PLATFORM_TAG

ARG BASE_IMAGE=${DOCKERHUB_USERNAME}/bash:${BASH_CHECKSUM}-${PLATFORM_TAG}

FROM ${BASE_IMAGE}

ARG IMAGE_FULL_NAME="noname"

ARG DEBIAN_FRONTEND=noninteractive
ARG NODE_VERSION=24.x
ARG NODE_ENV=production

ENV DEBIAN_FRONTEND=${DEBIAN_FRONTEND}
ENV NODE_ENV=${NODE_ENV}

RUN echo "IMAGE_FULL_NAME=${IMAGE_FULL_NAME}" > /etc/image-info

# Install Node.js
RUN set -x \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_VERSION nodistro main" | tee /etc/apt/sources.list.d/nodesource.list

RUN set -x \
    && apt-get update -y \
    && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    nodejs \
    && apt-get clean \
    && apt-get purge -y --auto-remove \
    && rm -rf /var/lib/apt/lists/*

# Copy .bashrc.d scripts
COPY home/ /home/devuser/
RUN find /home/devuser -type f -name '*.sh' -exec dos2unix {} \; -exec chmod +x {} \; && \
    find /home/devuser/.local/bin -type f -exec chmod +x {} \; && \
    chown devuser:devuser -R /home/devuser

USER devuser
WORKDIR /home/devuser
ENV PATH="/home/devuser/node_modules/.bin:${PATH}"

RUN set -eux; \
  if [ -f package-lock.json ] || [ -f npm-shrinkwrap.json ]; then \
    if [ "$NODE_ENV" = "production" ]; then \
      npm ci --omit=dev --no-audit --no-fund; \
    else \
      npm ci --no-audit --no-fund; \
    fi; \
  else \
    if [ "$NODE_ENV" = "production" ]; then \
      npm install --omit=dev --no-audit --no-fund; \
    else \
      npm install --no-audit --no-fund; \
    fi; \
  fi; \
  npm cache clean --force

USER root

# Crea directory template per la home (copia completa)
RUN cp -a $HOME_DIR/. /opt/home-template/



