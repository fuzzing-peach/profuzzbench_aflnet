#!/usr/bin/env bash

set -eu
set -o pipefail
cd $(dirname $0)
cd ..
source scripts/utils.sh

path=$1
fuzzer=$2
impl_version=${3:-latest}
protocol=${path%/*}
impl=${path##*/}
image_name=pingu-$fuzzer-$protocol-$impl:$impl_version
docker_build_args=$(get_arguments_after_double_dash $@)

log_success "[+] Building docker image: $image_name"
# If http proxy is required, passing:
# --build-arg HTTP_PROXY=http://172.17.0.1:7890 --build-arg HTTPS_PROXY=http://172.17.0.1:7890 
# If needs to add dns server, passing:
# --build-arg DNS_SERVER=9.9.9.9
docker build --build-arg FUZZER=$fuzzer --build-arg TARGET=$path --build-arg USER_UID="$(id -u)" --build-arg USER_GID="$(id -g)" -f scripts/Dockerfile $docker_build_args . -t $image_name
if [[ $? -ne 0 ]]; then
    log_error "[!] Error while building the docker image: $image_name"
    exit 1
else
    log_success "[+] Docker image successfully built: $image_name"
fi

exit 0