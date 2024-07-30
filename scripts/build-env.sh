#!/usr/bin/env bash

set -e
set -o pipefail
cd $(dirname $0)
cd ..
source scripts/utils.sh

docker_args=$(get_args_after_double_dash "$@")
log_success "[+] Building docker image: pingu-env:latest"
# If http proxy is required, passing:
# --build-arg HTTP_PROXY=http://172.17.0.1:7890 --build-arg HTTPS_PROXY=http://172.17.0.1:7890 
# If needs to add dns server, passing:
# --build-arg DNS_SERVER=9.9.9.9
DOCKER_BUILDKIT=1 docker build --build-arg USER_ID="$(id -u)" --build-arg GROUP_ID="$(id -g)" -f scripts/Dockerfile-env $docker_args . -t pingu-env:latest
if [[ $? -ne 0 ]]; then
    log_error "[!] Error while building the docker image: pingu-env:latest"
    exit 1
else
    log_success "[+] Docker image successfully built: pingu-env:latest"
fi

exit 0