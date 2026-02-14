FROM debian:trixie-slim

ENV FORCED_IMAGE_BUILD="2026-02-14 15:58"

ARG DEBIAN_FRONTEND=noninteractive
ARG IMAGE_FULL_NAME="noname"

ENV DEBIAN_FRONTEND=${DEBIAN_FRONTEND}
ENV USER=devuser
ENV GROUP=devgroup

ENV TZ=UTC
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV HOME=/home/$USER

ENV DPM_PROJECT_ROOT=/workdir

LABEL \
    org.opencontainers.image.ref.name="${IMAGE_FULL_NAME}"

RUN echo "IMAGE_FULL_NAME=${IMAGE_FULL_NAME}" > /etc/image-info

USER root

# explicitly set user/group IDs
RUN set -eux; \
    if getent passwd 1000 > /dev/null; then \
        OLD_USER=$(getent passwd 1000 | cut -d: -f1); \
        echo "Rimozione utente esistente: $OLD_USER"; \
        userdel -r $OLD_USER 2>/dev/null || userdel $OLD_USER; \
    fi; \
    if getent group 1000 > /dev/null; then \
        OLD_GROUP=$(getent group 1000 | cut -d: -f1); \
        echo "Rimozione gruppo esistente: $OLD_GROUP"; \
        groupdel $OLD_GROUP; \
    fi; \
    groupadd -r $GROUP --gid=1000; \
    useradd -r -g $GROUP --uid=1000 --home-dir=$HOME --shell=/bin/bash $USER; \
    install --verbose --directory --owner $USER --group $GROUP --mode 1777 $HOME

RUN set -x \
    && apt-get update -y \
    && apt-get install -y --no-install-recommends \
    apt-utils \
    ca-certificates \
    dumb-init \
    gosu \
    tzdata \
    locales \
    jq \
    yq \
    bash \
    file \
    git \
    gettext \
    openssl \
    openssh-client \
    sshpass \
    rsync \
    dos2unix \
    curl \
    wget \
    gnupg \
    screen \
    tmux \
    unzip \
    && apt-get upgrade -y \
    && apt-get clean \
    && apt-get purge -y --auto-remove \
    && rm -rf /var/lib/apt/lists/*

# Usa Bash invece di sh per tutti i RUN
SHELL ["/bin/bash", "-c"]

RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

RUN mkdir -p /opt/overrides/user_home
VOLUME /opt/overrides/user_home

RUN mkdir -p /opt/overrides/root_home
VOLUME /opt/overrides/root_home

# Create the .bashrc.d directory for the user (root by default in Docker)
RUN mkdir -p $HOME/.bashrc.d

# Copy all .sh files and the loader script from .bashrc.d to the respective .bashrc.d directories
COPY .bashrc.d/*.sh $HOME/.bashrc.d/
COPY .bashrc.d/load.sh $HOME/.bashrc.d/
COPY root/.bashrc.d/*.sh /root/.bashrc.d/
COPY root/.bashrc.d/load.sh /root/.bashrc.d/
# libs comuni
RUN mkdir -p /opt/bash_libs
COPY bash_libs /opt/bash_libs
RUN chmod -R 755 /opt/bash_libs

# Create a script that sources the .bashrc.d directory
RUN echo 'for f in ~/.bashrc.d/*.sh; do [ -f "$f" ] && source "$f"; done' >> $HOME/.bashrc

# Make sure all scripts are executable (forza conversione + fallback sed e verifica)
RUN set -eux; \
    echo "Normalizing shell scripts under /root/.bashrc.d"; \
    find "/root/.bashrc.d" -type f \( -name '*.sh' -o -name 'load.sh' \) -print | tee /tmp/bashrcd-files.txt; \
    while IFS= read -r f; do dos2unix -f "$f" >/dev/null 2>&1 || true; chmod 0755 "$f"; done </tmp/bashrcd-files.txt; \
    if grep -r $'\r' -n "/root/.bashrc.d"; then \
      echo "CRLF still present, applying sed fallback"; \
      while IFS= read -r f; do sed -i 's/\\r$//' "$f" || true; done </tmp/bashrcd-files.txt; \
    fi; \
    if grep -r $'\r' -n "/root/.bashrc.d"; then echo "❌ CRLF still present after normalization"; exit 1; else echo "✅ No CRLF remain"; fi

# Make sure all scripts are executable (forza conversione + fallback sed e verifica)
RUN set -eux; \
    echo "Normalizing shell scripts under $HOME/.bashrc.d"; \
    find "$HOME/.bashrc.d" -type f \( -name '*.sh' -o -name 'load.sh' \) -print | tee /tmp/bashrcd-files.txt; \
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


COPY docker-entrypoint.sh /usr/local/bin/

RUN find /usr/local/bin -type f -name '*.sh' -exec dos2unix {} \; -exec chmod +x {} \;

ENTRYPOINT ["/usr/bin/dumb-init","--","/usr/local/bin/docker-entrypoint.sh"]

WORKDIR /workdir

CMD ["bash","-lc","echo Nessuno comando specificato."]
