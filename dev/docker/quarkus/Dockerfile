ARG DOCKERHUB_USERNAME
ARG BASH_CHECKSUM
ARG PLATFORM_TAG

ARG BASE_IMAGE=${DOCKERHUB_USERNAME}/bash:${BASH_CHECKSUM}-${PLATFORM_TAG}

FROM ${BASE_IMAGE}

ARG IMAGE_FULL_NAME="quarkus-development"
ARG PLATFORM_TAG
# Versions and environment
ARG DEBIAN_FRONTEND=noninteractive
ARG NODE_VERSION=22.x
ARG NODE_ENV=production

ENV DEBIAN_FRONTEND=${DEBIAN_FRONTEND}
ENV NODE_ENV=${NODE_ENV}

ENV JAVA_VERSION="21.0.9-tem"
ENV GRAAL_VERSION="21.0.9-graal"
ENV MAVEN_VERSION="3.9.11"

LABEL \
    org.opencontainers.image.ref.name="${IMAGE_FULL_NAME}"

USER root

# Image metadata
RUN echo "IMAGE_FULL_NAME=${IMAGE_FULL_NAME}" > /etc/image-info


RUN apt-get update -y; \
    apt -y upgrade; \
    apt-get install -y --no-install-recommends \
    build-essential \
    zlib1g-dev \
    zip \
    && apt-get clean \
    && apt-get purge -y --auto-remove \
    && rm -rf /var/lib/apt/lists/*

ENV SDKMAN_DIR="/usr/local/sdkman"
RUN curl -s "https://get.sdkman.io?rcupdate=false" | bash && \
    chmod a+x "$SDKMAN_DIR/bin/sdkman-init.sh" && \
    echo "sdkman_auto_answer=true" > $SDKMAN_DIR/etc/config && \
    echo "sdkman_auto_selfupdate=false" >> $SDKMAN_DIR/etc/config && \
    echo "sdkman_insecure_ssl=false" >> $SDKMAN_DIR/etc/config

# Configurazione per SDKMAN
ENV PATH="$SDKMAN_DIR/bin:$PATH"

ENV JAVA_HOME="$SDKMAN_DIR/candidates/java/$JAVA_VERSION"
ENV JDK_HOME="$SDKMAN_DIR/candidates/java/$JAVA_VERSION"
ENV PATH="$JAVA_HOME/bin:$PATH"
RUN bash -c "source $SDKMAN_DIR/bin/sdkman-init.sh && sdk install java $JAVA_VERSION"

ENV GRAALVM_HOME="$SDKMAN_DIR/candidates/java/$GRAAL_VERSION"
RUN bash -c "source $SDKMAN_DIR/bin/sdkman-init.sh && sdk install java $GRAAL_VERSION"

ENV PATH="$SDKMAN_DIR/candidates/maven/$MAVEN_VERSION/bin:$PATH"

RUN bash -c "source $SDKMAN_DIR/bin/sdkman-init.sh && sdk install maven $MAVEN_VERSION"

RUN bash -c "source $SDKMAN_DIR/bin/sdkman-init.sh && sdk install quarkus"
ENV PATH="$SDKMAN_DIR/candidates/quarkus/current/bin:$PATH"

# --------


WORKDIR /workdir

EXPOSE 5005
EXPOSE 8080


# Create the .bashrc.d directory for the user (root by default in Docker)
RUN mkdir -p $HOME_DIR/.bashrc.d

# Copy all .sh files from .bashrc.d to the .bashrc.d directory
COPY .bashrc.d/ $HOME_DIR/.bashrc.d/
COPY root/.bashrc.d/ /root/.bashrc.d/

# Create a script that sources the .bashrc.d directory
RUN echo 'for f in ~/.bashrc.d/*.sh; do [ -f "$f" ] && source "$f"; done' >> $HOME_DIR/.bashrc


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

USER $USER

