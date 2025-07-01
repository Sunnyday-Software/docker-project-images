chmod +x ./dev/scripts/*.sh
chmod +x ./dpm/*

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
DOCKER_PLATFORM="linux/amd64"

# Map architecture names
case "$ARCH" in
    x86_64) ARCH="x86_64" ;;
    amd64)  ARCH="x86_64" ;;
    arm64)
      ARCH="arm64"
      DOCKER_PLATFORM="linux/arm64"
      ;;
    aarch64)
      ARCH="arm64"
      DOCKER_PLATFORM="linux/arm64"
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

cat <<EOF | $DPM_EXEC
(basedir-root)
(set-var "HOST_PROJECT_PATH" "\${CTX:basedir}")
(set-var "DOCKER_PLATFORM" "${DOCKER_PLATFORM}")
(read-env ".env.ci")
(read-env ".env.project")
(version-check "dev/docker")
(read-env "dev/docker/versions.properties")
(write-env ".env")
(debug)
(debug true)
(docker build-images)
EOF