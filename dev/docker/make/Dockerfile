
ARG DOCKERHUB_USERNAME
ARG BASH_CHECKSUM
ARG PLATFORM_TAG

ARG BASE_IMAGE=${DOCKERHUB_USERNAME}/bash:${BASH_CHECKSUM}-${PLATFORM_TAG}

FROM ${BASE_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
ARG IMAGE_FULL_NAME="noname"

ENV DEBIAN_FRONTEND=${DEBIAN_FRONTEND}

# Usa Bash invece di sh per tutti i RUN
SHELL ["/bin/bash", "-c"]


LABEL \
    org.opencontainers.image.ref.name="${IMAGE_FULL_NAME}"

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
RUN mkdir -p $HOME_DIR/.bashrc.d

# Copy all .sh files from .bashrc.d to the .bashrc.d directory
COPY .bashrc.d/*.sh $HOME_DIR/.bashrc.d/

# Create a script that sources the .bashrc.d directory
RUN echo 'for f in ~/.bashrc.d/*.sh; do [ -f "$f" ] && source "$f"; done' >> $HOME_DIR/.bashrc

# Make sure all scripts are executable (forza conversione + fallback sed e verifica)
RUN set -eux; \
    echo "Normalizing shell scripts under $HOME_DIR/.bashrc.d"; \
    find "$HOME_DIR/.bashrc.d" -type f -name '*.sh' -print | tee /tmp/bashrcd-files.txt; \
    while IFS= read -r f; do dos2unix -f "$f" >/dev/null 2>&1 || true; chmod 0755 "$f"; done </tmp/bashrcd-files.txt; \
    if grep -r $'\r' -n "$HOME_DIR/.bashrc.d"; then \
      echo "CRLF still present, applying sed fallback"; \
      while IFS= read -r f; do sed -i 's/\\r$//' "$f" || true; done </tmp/bashrcd-files.txt; \
    fi; \
    if grep -r $'\r' -n "$HOME_DIR/.bashrc.d"; then echo "❌ CRLF still present after normalization"; exit 1; else echo "✅ No CRLF remain"; fi

RUN chown -R $USER:$GROUP $HOME_DIR

# Crea directory template per la home (copia completa)
RUN mkdir -p /opt/home-template && \
    cp -a $HOME_DIR/. /opt/home-template/ && \
    echo "✅ Home template created in /opt/home-template"


COPY docker-entrypoint.sh /usr/local/bin/

RUN find /usr/local/bin -type f -name '*.sh' -exec dos2unix {} \; -exec chmod +x {} \;

ENTRYPOINT ["/usr/bin/dumb-init","--","/usr/local/bin/docker-entrypoint.sh"]

WORKDIR /workdir

CMD ["bash","-lc","echo Nessuno comando specificato."]
