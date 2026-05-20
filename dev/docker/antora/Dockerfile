ARG DOCKERHUB_USERNAME
ARG BASH_CHECKSUM
ARG PLATFORM_TAG

ARG BASE_IMAGE=${DOCKERHUB_USERNAME}/bash:${BASH_CHECKSUM}-${PLATFORM_TAG}

FROM ${BASE_IMAGE}

ARG IMAGE_FULL_NAME="noname"
ARG DEBIAN_FRONTEND=noninteractive
ARG NODE_VERSION=24.x
ARG NODE_ENV=production
ARG ANTORA_UI_BUNDLE_URL=https://gitlab.com/antora/antora-ui-default/-/jobs/artifacts/HEAD/raw/build/ui-bundle.zip?job=bundle-stable

ENV DEBIAN_FRONTEND=${DEBIAN_FRONTEND}
ENV NODE_ENV=${NODE_ENV}
ENV ANTORA_CACHE_DIR=/workdir/.runtime/antora/cache
ENV KROKI_SERVER_URL=http://docs-kroki:8000

USER root

RUN echo "IMAGE_FULL_NAME=${IMAGE_FULL_NAME}" > /etc/image-info

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

COPY home/ /home/devuser/
RUN echo 'for f in ~/.bashrc.d/*.sh; do [ -f "$f" ] && source "$f"; done' >> $HOME/.bashrc

RUN set -eux; \
    echo "Normalizing shell scripts under $HOME/.bashrc.d"; \
    if [ -d "$HOME/.bashrc.d" ]; then \
        find "$HOME/.bashrc.d" -type f -name '*.sh' -print | tee /tmp/bashrcd-files.txt; \
        while IFS= read -r f; do dos2unix -f "$f" >/dev/null 2>&1 || true; chmod 0755 "$f"; done </tmp/bashrcd-files.txt; \
        if grep -r $'\r' -n "$HOME/.bashrc.d" 2>/dev/null; then \
          echo "CRLF still present, applying sed fallback"; \
          while IFS= read -r f; do sed -i 's/\\r$//' "$f" || true; done </tmp/bashrcd-files.txt; \
        fi; \
        if grep -r $'\r' -n "$HOME/.bashrc.d" 2>/dev/null; then \
            echo "CRLF still present after normalization"; exit 1; \
        else \
            echo "No CRLF remain"; \
        fi; \
    fi

USER $USER
WORKDIR /home/devuser
ENV PATH="/home/devuser/node_modules/.bin:/home/devuser/.local/bin:${PATH}"

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

RUN mkdir -p /opt/antora/ui \
    && wget -O /opt/antora/ui/ui-bundle.zip "${ANTORA_UI_BUNDLE_URL}"

RUN cp -a $HOME/. /opt/home-template/ && \
    echo "Home template updated with Antora files"

USER $USER
WORKDIR /workdir
