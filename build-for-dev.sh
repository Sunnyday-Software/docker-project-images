# (opzionale) abilita BuildKit per build più veloce
export DOCKER_BUILDKIT=1
export PLATFORM="linux/arm64"
export PLATFORM_TAG="arm64"

build_image() {
  local image_base_path="$1"
  local image_name="$2"
  local base_image_name="$3"

  docker build \
    --platform $PLATFORM \
    --build-arg PLATFORM_TAG="$PLATFORM_TAG" \
    --build-arg IMAGE_FULL_NAME="${image_name}:localdev"  \
    --build-arg BASE_IMAGE="${base_image_name}" \
    -t $image_name:localdev \
    "$image_base_path/$image_name"

}

#build_image "dev/docker" "bash"
#build_image "dev/docker" "make"
build_image "dev/docker" "node-semantic-release" "bash:localdev"