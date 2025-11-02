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

# Fase 0: Preparazione file dipendenze
mv "./dev/docker/versions.properties" "./dev/docker/versions.properties.backup"
./dev/scripts/docker_prepare_dependencies_info.sh

# Calcola la versione senza le dipendenze, soltanto
TMPFILE="$(mktemp -t dpm_cfg.XXXXXX)"

cat >"$TMPFILE" <<EOF
(basedir-root)
(version-check "dev/docker")
EOF

"$DPM_EXEC" --file "$TMPFILE"

./dev/scripts/docker_prepare_dependencies_info_step_2.sh
mv "./dev/docker/versions.properties.backup" "./dev/docker/versions.properties"



# Fase 1: Aggiorna versions.properties
echo "=== Fase 1: Aggiornamento versions.properties ==="
# Prepara contenuto di configurazione per DPM ed evita la pipe: usa un file temporaneo
TMPFILE="$(mktemp -t dpm_cfg.XXXXXX)"

cat >"$TMPFILE" <<EOF
(basedir-root)
(version-check "dev/docker")
EOF

"$DPM_EXEC" --file "$TMPFILE"
EXIT_CODE=$?




# Fase 2: Build e Push delle immagini
echo "=== Fase 2: Build e Push delle immagini ==="
TMPFILE="$(mktemp -t dpm_cfg.XXXXXX)"

cat >"$TMPFILE" <<EOF
(basedir-root)
(set-var "HOST_PROJECT_PATH" "\${CTX:basedir}")
(set-var "DOCKER_PLATFORM" "${DOCKER_PLATFORM}")
(set-var "PLATFORM_TAG" "${PLATFORM_TAG}")
(read-env ".env.ci")
(read-env ".env.project")
(read-env "dev/docker/versions.properties")
(write-env ".env")
EOF

"$DPM_EXEC" --file "$TMPFILE"
EXIT_CODE=$?

./dev/scripts/docker_image_build_and_push_script.sh