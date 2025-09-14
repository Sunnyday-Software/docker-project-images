FROM ubuntu:noble

ARG DEBIAN_FRONTEND=noninteractive
ARG IMAGE_FULL_NAME="noname"

ENV TZ=UTC
ENV LANG=en_US.utf8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV HOME_DIR=/root

RUN echo "IMAGE_FULL_NAME=${IMAGE_FULL_NAME}" > /etc/image-info

RUN set -x \
    && apt-get update -y \
    && apt-get install -y --no-install-recommends \
    apt-utils \
    build-essential \
    ca-certificates \
    pkg-config \
    cmake \
    gettext \
    git \
    wget \
    dumb-init \
    gosu \
    tzdata \
    locales \
    jq \
    bash \
    openssl \
    rsync \
    dos2unix \
    curl \
    gnupg \
    openssh-client \
    screen \
    tree \
    make \
    && apt-get clean \
    && apt-get purge -y --auto-remove \
    && rm -rf /var/lib/apt/lists/*

RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

RUN set -x \
    && curl -fsSL https://get.docker.com -o ./install-docker.sh \
    && chmod +x ./install-docker.sh \
    && ./install-docker.sh \
    && apt-get clean \
    && apt-get purge -y --auto-remove \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workdir


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


COPY docker-entrypoint.sh /usr/local/bin/
COPY git-credential-gpg.sh /usr/local/bin/

RUN find /usr/local/bin -type f -name '*.sh' -exec dos2unix {} \; -exec chmod +x {} \;

ENTRYPOINT ["/usr/bin/dumb-init","--","/usr/local/bin/docker-entrypoint.sh"]

CMD ["bash","-lc","echo Nessuno comando specificato."]
