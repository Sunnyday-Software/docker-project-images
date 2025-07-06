#!/usr/bin/env bash

chmod +x ./dev/scripts/*.sh
chmod +x ./dpm/*

export DOCKER_BUILDKIT=1

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
DOCKER_PLATFORM="linux/amd64"
PLATFORM_TAG="amd64"

# Map architecture names
case "$ARCH" in
    x86_64) ARCH="x86_64" ;;
    amd64)  ARCH="x86_64" ;;
    arm64)
      ARCH="arm64"
      DOCKER_PLATFORM="linux/arm64"
      PLATFORM_TAG="arm64"
      ;;
    aarch64)
      ARCH="arm64"
      DOCKER_PLATFORM="linux/arm64"
      PLATFORM_TAG="arm64"
      ;;
    *) echo "Unsupported architecture: $ARCH" && exit 1 ;;
esac

# Select appropriate DPM executable
case "$OS" in
    linux)
        DPM_EXEC="./dpm/dpm-linux-${ARCH}-musl"
        ;;
    darwin)
        DPM_EXEC="./dpm/dpm-macos-${ARCH}"
        ;;
    *)
        echo "Unsupported operating system: $OS" && exit 1
        ;;
esac


# Fase 1: Aggiorna versions.properties
echo "=== Fase 1: Aggiornamento versions.properties ==="
cat <<EOF | $DPM_EXEC
(basedir-root)
(version-check "dev/docker")
EOF

# Verifica se ci sono stati cambiamenti nel file versions.properties
if [ -n "$(git status --porcelain dev/docker/versions.properties)" ]; then
    echo "=== Rilevati cambiamenti in versions.properties ==="

    # Commit e push dei cambiamenti
    git add dev/docker/versions.properties
    git commit -m "chore: update Docker image versions [ci skip]"
    git push origin HEAD

fi


# Fase 2: Build e Push delle immagini
echo "=== Fase 2: Build e Push delle immagini ==="
cat <<EOF | $DPM_EXEC
(basedir-root)
(set-var "HOST_PROJECT_PATH" "\${CTX:basedir}")
(set-var "DOCKER_PLATFORM" "${DOCKER_PLATFORM}")
(set-var "PLATFORM_TAG" "${PLATFORM_TAG}")
(read-env ".env.ci")
(read-env ".env.project")
(read-env "dev/docker/versions.properties")
(write-env ".env")
EOF

./dev/scripts/docker_image_build_and_push_script.sh