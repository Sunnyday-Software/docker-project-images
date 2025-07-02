FROM ubuntu:noble

ARG DEBIAN_FRONTEND=noninteractive

ENV TZ=UTC
ENV LANG=en_US.utf8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8


RUN apt-get update -y; \
    apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    pkg-config \
    cmake \
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

COPY docker-entrypoint.sh /usr/local/bin/
RUN dos2unix /usr/local/bin/*.sh ; \
    chmod +x /usr/local/bin/*.sh;

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["echo 'Nessuno comando specificato.'"]