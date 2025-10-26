
FROM ubuntu:noble

ARG DEBIAN_FRONTEND=noninteractive
ARG IMAGE_FULL_NAME="noname"

ENV DEBIAN_FRONTEND=${DEBIAN_FRONTEND}
ENV USER=bashuser
ENV GROUP=bashuser
ENV TZ=UTC
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV HOME_DIR=/home/$USER

LABEL \
    org.opencontainers.image.ref.name="${IMAGE_FULL_NAME}"

RUN echo "IMAGE_FULL_NAME=${IMAGE_FULL_NAME}" > /etc/image-info

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
    useradd -r -g $GROUP --uid=1000 --home-dir=$HOME_DIR --shell=/bin/bash $USER; \
    install --verbose --directory --owner $USER --group $GROUP --mode 1777 $HOME_DIR

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
    bash \
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
    && apt-get clean \
    && apt-get purge -y --auto-remove \
    && rm -rf /var/lib/apt/lists/*


RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8


COPY docker-entrypoint.sh /usr/local/bin/
RUN set -x \
    && find /usr/local/bin -type f -name '*.sh' -exec dos2unix {} \; -exec chmod +x {} \;

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]



# Create the .bashrc.d directory for the user (root by default in Docker)
RUN mkdir -p $HOME_DIR/.bashrc.d

# Copy all .sh files from .bashrc.d to the .bashrc.d directory
COPY .bashrc.d/*.sh $HOME_DIR/.bashrc.d/

# Create a script that sources the .bashrc.d directory
RUN echo 'for f in ~/.bashrc.d/*.sh; do [ -f "$f" ] && source "$f"; done' >> $HOME_DIR/.bashrc

# Make sure all scripts are executable
RUN set -x \
    && find $HOME_DIR -type f -name '*.sh' -exec dos2unix {} \; -exec chmod +x {} \; \
    && chown $USER:$GROUP -R $HOME_DIR/.bashrc.d

VOLUME ["/home/bashuser/.ssh"]
USER $USER

ENV PATH="$HOME_DIR/.local/bin:${PATH}"

USER bashuser

# Set the working directory
WORKDIR /workdir

# Imposta l'entrypoint per eseguire lo script passato come parametro
CMD ["echo", "Nessuno script specificato."]
