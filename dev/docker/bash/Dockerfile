
FROM ubuntu:noble

ARG DEBIAN_FRONTEND=noninteractive

ENV USER=bashuser
ENV GROUP=bashuser
ENV TZ=UTC
ENV LANG=en_US.utf8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV HOME_DIR=/home/$USER

# explicitly set user/group IDs
RUN set -eux; \
    groupadd -r $GROUP --gid=999; \
    useradd -r -g $GROUP --uid=999 --home-dir=$HOME_DIR --shell=/bin/bash $USER; \
    install --verbose --directory --owner $USER --group $GROUP --mode 1777 $HOME_DIR

RUN apt-get update -y; \
    apt-get install -y --no-install-recommends \
    apt-utils \
    ca-certificates \
    dumb-init \
    gosu \
    tzdata \
    locales \
    jq \
    bash \
    openssl \
    openssh-client \
    sshpass \
    rsync \
    dos2unix \
    curl \
    gnupg \
    screen \
    tmux \
    unzip \
    python3 \
    python3-pip \
    python3-venv \
    python3-setuptools \
    pipx \
    ;

RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

# Imposta PIPX e installa librerie globalmente per tutti (con --global)
ENV PIPX_HOME=/opt/pipx
ENV PIPX_BIN_DIR=/usr/local/bin


COPY docker-entrypoint.sh /usr/local/bin/
RUN dos2unix /usr/local/bin/*.sh ; \
    chmod +x /usr/local/bin/*.sh;

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Set the working directory
WORKDIR /workdir

# Create the .bashrc.d directory for the user (root by default in Docker)
RUN mkdir -p $HOME_DIR/.bashrc.d

# Copy all .sh files from .bashrc.d to the .bashrc.d directory
COPY .bashrc.d/*.sh $HOME_DIR/.bashrc.d/

# Create a script that sources the .bashrc.d directory
RUN echo 'for f in ~/.bashrc.d/*.sh; do [ -f "$f" ] && source "$f"; done' >> $HOME_DIR/.bashrc

# Make sure all scripts are executable
RUN dos2unix $HOME_DIR/*.sh ; \
    chmod -R +x $HOME_DIR/*.sh; \
    chown $USER:$GROUP -R $HOME_DIR/.bashrc.d

VOLUME ["/home/bashuser/.ssh"]
USER $USER

ENV PATH="$HOME_DIR/.local/bin:${PATH}"

USER root

# Imposta l'entrypoint per eseguire lo script passato come parametro
CMD ["echo", "Nessuno script specificato."]
