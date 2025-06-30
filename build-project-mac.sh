chmod +x ./dev/scripts/*.sh
chmod +x ./dpm/*

cat <<EOF | ./dpm/dpm-macos-arm64
(basedir-root)
(set-var "HOST_PROJECT_PATH" "\${CTX:basedir}")
(set-var "CI" "false")
(read-env ".env.project")
(read-env ".env.local")
(version-check "dev/docker")
(read-env "dev/docker/versions.properties")
(write-env ".env")
(debug)
(debug true)
(docker build-images)
(docker debug-in-vm)
(docker push-images)
EOF