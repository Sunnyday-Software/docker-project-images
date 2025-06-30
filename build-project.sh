chmod +x ./dev/scripts/*.sh
chmod +x ./dpm/*

cat <<EOF | ./dpm/dpm-linux-x86_64-musl
(basedir-root)
(set-var "HOST_PROJECT_PATH" "\${CTX:basedir}")
(read-env ".env.project")
(read-env ".env.local")
(version-check "dev/docker")
(read-env "dev/docker/versions.properties")
(write-env ".env")
(debug)
(debug true)
(docker debug-in-vm)
(docker push-images)
EOF