#https://opentofu.org/docs/intro/install/standalone/
ARG DOCKERHUB_USERNAME
ARG BASH_CHECKSUM
ARG PLATFORM_TAG
ARG IMAGE_FULL_NAME="noname"
ARG BASE_IMAGE=${DOCKERHUB_USERNAME}/bash:${BASH_CHECKSUM}-${PLATFORM_TAG}

FROM ${BASE_IMAGE}

USER root

RUN echo "IMAGE_FULL_NAME=${IMAGE_FULL_NAME}" > /etc/image-info

RUN curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
RUN chmod +x install-opentofu.sh
RUN ./install-opentofu.sh --install-method standalone
RUN rm -f install-opentofu.sh


USER bashuser
