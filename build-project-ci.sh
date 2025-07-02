chmod +x ./dev/scripts/*.sh
chmod +x ./dpm/*

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

# Set default platform if not defined
if [ -z "${DOCKER_PLATFORM}" ]; then
    DOCKER_PLATFORM="linux/amd64"
    PLATFORM_TAG="amd64"
fi

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
        if [ "$ARCH" = "arm64" ]; then
            DPM_EXEC="./dpm/dpm-linux-arm64"
        else
            DPM_EXEC="./dpm/dpm-linux-${ARCH}-musl"
        fi

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

    # Push solo se non siamo in modalità CI o se esplicitamente richiesto
    if [ "${CI_PUSH_VERSIONS:-false}" = "true" ]; then
        git push origin HEAD
        echo "=== Versions pushate. Fermando l'esecuzione per permettere un nuovo run della CI ==="
        exit 0
    else
        echo "=== Cambiamenti committati localmente. Ricorda di fare push prima della build ==="
    fi
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
(debug)
(debug true)
(docker build-images)
(docker push-images)
EOF