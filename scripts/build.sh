#!/usr/bin/env bash

set -e
set -o pipefail
cd $(dirname $0)
cd ..
source scripts/utils.sh

# Parameters after -- is passed directly to the docker build
args=($(get_args_before_double_dash "$@"))
docker_args=$(get_args_after_double_dash "$@")

opt_args=`getopt -o f:t:v: -l fuzzer:,target:,version: --name "$0" -- "${args[@]}"`
if [ $? != 0 ]; then
    log_error "[!] Error in parsing shell arguments."
    exit 1
fi

eval set -- "${opt_args}"
while true
do
    case "$1" in 
        -f|--fuzzer)
            fuzzer="$2"
            shift 2
            ;;
        -t|--target)
            target="$2"
            shift 2
            ;;
        -v|--version)
            if [[ -n "$2" && "$2" != "--" ]]; then
                version="$2"
                shift 2
            else
                log_error "[!] Option -v|--version requires a non-empty value."
                exit 1
            fi
            ;;
        *)
            break
            ;;
    esac
done

protocol=${target%/*}
impl=${target##*/}
image_name=$(echo "pingu-$fuzzer-$protocol-$impl:${version:-latest}" | tr 'A-Z' 'a-z')

log_success "[+] Building docker image: $image_name"
# If http proxy is required, passing:
# --build-arg HTTP_PROXY=http://172.17.0.1:7890 --build-arg HTTPS_PROXY=http://172.17.0.1:7890 
# If needs to add dns server, passing:
# --build-arg DNS_SERVER=9.9.9.9
docker build --build-arg FUZZER=$fuzzer --build-arg TARGET=$target --build-arg VERSION=$version --build-arg USER_UID="$(id -u)" --build-arg USER_GID="$(id -g)" -f scripts/Dockerfile $docker_args . -t $image_name
if [[ $? -ne 0 ]]; then
    log_error "[!] Error while building the docker image: $image_name"
    exit 1
else
    log_success "[+] Docker image successfully built: $image_name"
fi

exit 0