FROM ubuntu:noble

ARG DEBIAN_FRONTEND=noninteractive
ARG IMAGE_FULL_NAME

ENV TZ=UTC
ENV LANG=en_US.utf8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV HOME_DIR=/root

RUN echo "IMAGE_FULL_NAME=${IMAGE_FULL_NAME}" > /etc/image-info

RUN apt-get update -y; \
    apt-get install -y --no-install-recommends \
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
    screen \
    tree \
    make \
    ; \
    rm -rf /var/lib/apt/lists/*

RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

RUN curl -fsSL https://get.docker.com -o ./install-docker.sh; \
    chmod +x ./install-docker.sh; \
    ./install-docker.sh


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

COPY docker-entrypoint.sh /usr/local/bin/
COPY git-credential-gpg.sh /usr/local/bin/
RUN dos2unix /usr/local/bin/*.sh ; \
    chmod +x /usr/local/bin/*.sh;

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["echo 'Nessuno comando specificato.'"]