# Docker Project Images - Development Guidelines

This document provides guidelines for developing and maintaining the Docker Project Images repository, which contains a collection of Docker images used for builds.

## Build/Configuration Instructions

### Environment Setup

1. **Environment Variables**:
   - Create a `.env` file in the project root with the following variables:
     ```
     PROJECT_NAME=docker-project-images
     DOCKER_HOST_MAP=/var/run/docker.sock:/var/run/docker.sock
     DOCKERHUB_USERNAME=your_dockerhub_username
     OPENTOFU_RELEASE=1.9.0
     DOCKERHUB_TOKEN=${DOCKERHUB_TOKEN}
     CI=${CI}
     HOST_PROJECT_PATH=/path/to/your/project
     ```
   - For CI environments, a separate `.env.docker` file is used

2. **MD5 Hash Generation**:
   - MD5 hashes are used for versioning Docker images
   - Hashes are generated based on the content of each Docker directory
   - The script `dev/scripts/gen-md5-and-build.sh` generates these hashes and exports them as environment variables (e.g., `MD5_BASH`, `MD5_MAKE`, `MD5_OPENTOFU`)

### Building Images

1. **Using Make**:
   ```bash
   make build-images
   ```
   This command:
   - Verifies if Docker images need to be rebuilt using `dev/scripts/docker_image_verification.sh`
   - If needed, builds the images using `dev/scripts/docker_build_images.sh`

2. **Using Docker Compose Directly**:
   ```bash
   # Generate MD5 hashes and build all images
   ./dev/scripts/gen-md5-and-build.sh
   
   # Or build specific images
   docker compose build bash
   docker compose build make
   docker compose build opentofu
   ```

3. **Image Dependencies**:
   - The `bash` image must be built first as it's a dependency for other images
   - The `opentofu` image depends on the `bash` image

### Pushing Images

```bash
make push-images
```
This command pushes the built images to Docker Hub using the credentials specified in the environment variables.

## Testing Information

### Testing Docker Images

1. **Verification Script**:
   - The `dev/scripts/docker_image_verification.sh` script checks if images need to be rebuilt
   - It compares the MD5 hashes of the Docker directories with the tags of the existing images

2. **Manual Testing**:
   - Create a test script similar to `test_env.sh` to verify that images can be built and run correctly
   - Example test script:
     ```bash
     #!/bin/bash
     
     # Test bash image
     docker build -t test/bash:latest ./dev/docker/bash
     docker run --rm test/bash:latest echo "Bash image works!"
     
     # Test make image
     docker build -t test/make:latest ./dev/docker/make
     docker run --rm test/make:latest make --version
     ```

3. **Adding New Tests**:
   - Create test scripts in a new `tests` directory
   - Ensure tests verify both the build process and the functionality of the images
   - Include tests for any new features or images added to the project

## Additional Development Information

### Project Structure

- **Docker Images**:
  - `bash`: Base image with common tools and utilities
  - `make`: Image with make and Docker capabilities
  - `opentofu`: Image with OpenTofu (Terraform alternative)

- **Key Scripts**:
  - `dev/scripts/gen-md5-and-build.sh`: Generates MD5 hashes and builds images
  - `dev/scripts/docker_image_verification.sh`: Verifies if images need to be rebuilt
  - `dev/scripts/docker_build_images.sh`: Builds Docker images
  - `dev/scripts/push-images.sh`: Pushes images to Docker Hub

### Code Style and Conventions

1. **Dockerfile Best Practices**:
   - Use specific base image versions (e.g., `ubuntu:noble`)
   - Group related commands in a single RUN instruction to reduce layers
   - Clean up package manager caches to reduce image size
   - Use multi-stage builds where appropriate

2. **Script Conventions**:
   - Use `set -e` to exit on errors
   - Include proper error handling and logging
   - Make scripts executable and use proper shebang lines
   - Convert scripts to Unix format using `dos2unix`

3. **Environment Variables**:
   - Use uppercase for environment variable names
   - Document all required environment variables
   - Provide sensible defaults where possible

### Adding New Docker Images

1. Create a new directory in `dev/docker/` with the name of the image
2. Create a Dockerfile and any necessary scripts
3. Add the image to `docker-compose.yml`
4. Update the version tracking file in `dev/docker_versions/`
5. Test the image using the testing process described above

### Debugging

- Use the `debug-in-vm` make target to debug in a virtual machine
- Check Docker logs for build issues
- Verify environment variables are set correctly