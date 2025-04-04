#https://opentofu.org/docs/intro/install/standalone/
ARG DOCKERHUB_USERNAME
ARG MD5_BASH

FROM ${DOCKERHUB_USERNAME}-bash:${MD5_BASH}

USER root
RUN curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
RUN chmod +x install-opentofu.sh
RUN ./install-opentofu.sh --install-method standalone
RUN rm -f install-opentofu.sh


USER bashuser
