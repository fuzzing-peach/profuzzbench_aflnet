#!/usr/bin/env bash

set -e
set -o pipefail
cd $(dirname $0)
cd ..
source scripts/utils.sh

# Parameters after -- is passed directly to the run script
args=($(get_args_before_double_dash "$@"))
fuzzer_args=$(get_arguments_after_double_dash "$@")

opt_args=`getopt -o o:f:t:v:: -l output:,fuzzer:,target:,version::,times:,timeout: -- "${args[@]}"`
if [ $? != 0 ]; then
    log_error "[!] Error in parsing shell arguments."
    exit 1
fi

eval set -- "${opt_args}"
while true
do
    case "$1" in 
        -o|--output)
            output="$2"
            shift 2
            ;;
        -f|--fuzzer)
            fuzzer="$2"
            shift 2
            ;;
        -t|--target)
            target="$2"
            shift 2
            ;;
        -v|--version)
            version="$2"
            shift 2
            ;;
        --times)
            times="$2"
            shift 2
            ;;
        --timeout)
            timeout="$2"
            shift 2
            ;;
        *)
            # echo "Usage: run.sh -t TARGET -f FUZZER -v VERSION [--times TIMES, --timeout TIMEOUT]"
            break
            ;;
    esac
done

# if [ ${#args[@]} -lt 4 ]; then
#     log_error "[!] Insufficient arguments, require: <target> <fuzzer> <times> <timeout>"
#     exit 1
# fi

protocol=${target%/*}
impl=${target##*/}
impl_version=${version:-latest}
image_name=$(echo "pingu-$fuzzer-$protocol-$impl:$impl_version" | tr 'A-Z' 'a-z')

image_id=$(docker images -q "$image_name")
if [[ -n "$image_id" ]]; then
    log_success "[+] Using docker image: $image_name"
else
    log_error "[!] Docker image not found: $image_name"
    exit 1
fi

cids=()
for i in $(seq 1 $times); do
# TODO:
#   id=$(docker run -d -it $image_name /bin/bash -c "cd ${WORKDIR} && run ${FUZZER} ${OUTDIR} '${OPTIONS}' ${TIMEOUT} ${SKIPCOUNT}")
  log_success "[+] Launch docker container: $i"
  cids+=(${id::12}) #store only the first 12 characters of a container ID
done

dlist="" #docker list
for id in ${cids[@]}; do
  dlist+=" ${id}"
done

# wait until all these dockers are stopped
log_success "[+] Fuzzing in progress ..."
log_success "[+] Waiting for the following containers to stop: ${dlist}"
docker wait ${dlist} > /dev/null
wait

# TODO: