
ARG DOCKERHUB_USERNAME
ARG BASH_CHECKSUM
ARG PLATFORM_TAG

ARG BASE_IMAGE=${DOCKERHUB_USERNAME}/bash:${BASH_CHECKSUM}-${PLATFORM_TAG}

FROM ${BASE_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
ARG IMAGE_FULL_NAME="noname"

ENV DEBIAN_FRONTEND=${DEBIAN_FRONTEND}

LABEL \
    org.opencontainers.image.ref.name="${IMAGE_FULL_NAME}"

USER root

RUN echo "IMAGE_FULL_NAME=\"${IMAGE_FULL_NAME}\"" > /etc/image-info


RUN set -x \
    && apt-get update -y \
    && apt-get install -y --no-install-recommends \
    build-essential \
    pkg-config \
    cmake \
    make \
    && apt-get clean \
    && apt-get purge -y --auto-remove \
    && rm -rf /var/lib/apt/lists/*

RUN set -x \
    && curl -fsSL https://get.docker.com -o ./install-docker.sh \
    && chmod +x ./install-docker.sh \
    && ./install-docker.sh \
    && apt-get clean \
    && apt-get purge -y --auto-remove \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    usermod -aG docker $USER

RUN git config --global --add safe.directory /workdir

# Create the .bashrc.d directory for the user (root by default in Docker)
RUN mkdir -p $HOME/.bashrc.d

# Copy all .sh files from .bashrc.d to the .bashrc.d directory
COPY .bashrc.d/ $HOME/.bashrc.d/
COPY root/.bashrc.d/ /root/.bashrc.d/

# Create a script that sources the .bashrc.d directory
RUN echo 'for f in ~/.bashrc.d/*.sh; do [ -f "$f" ] && source "$f"; done' >> $HOME/.bashrc


# Make sure all scripts are executable (forza conversione + fallback sed e verifica)
RUN set -eux; \
    echo "Normalizing shell scripts under /root/.bashrc.d"; \
    find "/root/.bashrc.d" -type f -name '*.sh' -print | tee /tmp/bashrcd-files.txt; \
    while IFS= read -r f; do dos2unix -f "$f" >/dev/null 2>&1 || true; chmod 0755 "$f"; done </tmp/bashrcd-files.txt; \
    if grep -r $'\r' -n "/root/.bashrc.d"; then \
      echo "CRLF still present, applying sed fallback"; \
      while IFS= read -r f; do sed -i 's/\\r$//' "$f" || true; done </tmp/bashrcd-files.txt; \
    fi; \
    if grep -r $'\r' -n "/root/.bashrc.d"; then echo "❌ CRLF still present after normalization"; exit 1; else echo "✅ No CRLF remain"; fi

# Make sure all scripts are executable (forza conversione + fallback sed e verifica)
RUN set -eux; \
    echo "Normalizing shell scripts under $HOME/.bashrc.d"; \
    find "$HOME/.bashrc.d" -type f -name '*.sh' -print | tee /tmp/bashrcd-files.txt; \
    while IFS= read -r f; do dos2unix -f "$f" >/dev/null 2>&1 || true; chmod 0755 "$f"; done </tmp/bashrcd-files.txt; \
    if grep -r $'\r' -n "$HOME/.bashrc.d"; then \
      echo "CRLF still present, applying sed fallback"; \
      while IFS= read -r f; do sed -i 's/\\r$//' "$f" || true; done </tmp/bashrcd-files.txt; \
    fi; \
    if grep -r $'\r' -n "$HOME/.bashrc.d"; then echo "❌ CRLF still present after normalization"; exit 1; else echo "✅ No CRLF remain"; fi

RUN chown -R $USER:$GROUP $HOME

# Crea directory template per la home (copia completa)
RUN mkdir -p /opt/home-template && \
    cp -a $HOME/. /opt/home-template/ && \
    echo "✅ Home template created in /opt/home-template"

