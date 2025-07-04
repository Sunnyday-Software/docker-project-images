
ARG DOCKERHUB_USERNAME
ARG BASH_CHECKSUM
ARG PLATFORM_TAG

FROM ${DOCKERHUB_USERNAME}/bash:${BASH_CHECKSUM}-${PLATFORM_TAG}

ARG NODE_VERSION=22.x
ARG DEBIAN_FRONTEND=noninteractive

# Install Node.js
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    apt-utils \
    ca-certificates \
    curl \
    gnupg \
    build-essential \
    git

RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_VERSION nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get update -y

RUN apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Yarn
RUN npm install -g yarn

# Install semantic-release and common plugins
RUN npm install -g \
    semantic-release \
    @semantic-release/commit-analyzer \
    @semantic-release/release-notes-generator \
    @semantic-release/changelog \
    @semantic-release/npm \
    @semantic-release/github \
    @semantic-release/git

RUN npm install -g \
    @commitlint/cli \
    @commitlint/config-conventional

# Install additional tools useful for CI/CD
RUN npm install -g \
    commitizen \
    cz-conventional-changelog \
    standard-version

# Configure commitizen to use conventional changelog
RUN echo '{ "path": "cz-conventional-changelog" }' > /home/bashuser/.czrc

# Create a wrapper script for semantic-release that uses the global config
RUN cat > /usr/local/bin/semantic-release-wrapper << 'EOF'
#!/bin/bash

# Set default config file if none exists in the project
if [ ! -f .releaserc.json ] && [ ! -f .releaserc.yml ] && [ ! -f .releaserc.yaml ] && [ ! -f .releaserc.js ]; then
    echo "Using default semantic-release configuration..."
    export SEMANTIC_RELEASE_CONFIG="/home/bashuser/.config/semantic-release/config.json"
    semantic-release --extends "$SEMANTIC_RELEASE_CONFIG" "$@"
else
    echo "Using project-specific semantic-release configuration..."
    semantic-release "$@"
fi
EOF

RUN chmod +x /usr/local/bin/semantic-release-wrapper


# Set up environment for GitHub Actions
ENV CI=true
ENV GITHUB_ACTIONS=true

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN dos2unix /usr/local/bin/*.sh && \
    chmod +x /usr/local/bin/*.sh

# Copy .bashrc.d scripts
COPY .bashrc.d/*.sh /home/bashuser/.bashrc.d/
RUN dos2unix /home/bashuser/.bashrc.d/*.sh && \
    chmod +x /home/bashuser/.bashrc.d/*.sh && \
    chown bashuser:bashuser -R /home/bashuser/.bashrc.d

# Set working directory
WORKDIR /workdir

# Switch to non-root user for better security
USER bashuser

# Create default semantic-release configuration that works globally
RUN mkdir -p /home/bashuser/.config/semantic-release
RUN cat > /home/bashuser/.config/semantic-release/config.json << 'EOF'
{
  "branches": ["main", "master"],
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    "@semantic-release/changelog",
    "@semantic-release/npm",
    "@semantic-release/github",
    [
      "@semantic-release/git",
      {
        "assets": ["CHANGELOG.md", "package.json", "package-lock.json"],
        "message": "chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}"
      }
    ]
  ]
}
EOF

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Default command
CMD ["node", "--version"]
