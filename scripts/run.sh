#!/usr/bin/env bash

set -e
set -o pipefail
cd $(dirname $0)
cd ..
source scripts/utils.sh

# Parameters after -- is passed directly to the run script
args=($(get_args_before_double_dash "$@"))
fuzzer_args=$(get_args_after_double_dash "$@")

opt_args=$(getopt -o o:f:t:v: -l output:,fuzzer:,generator:,target:,version:,times:,timeout:,cleanup -- "${args[@]}")
if [ $? != 0 ]; then
    log_error "[!] Error in parsing shell arguments."
    exit 1
fi

eval set -- "${opt_args}"
while true; do
    case "$1" in
    -o | --output)
        output="$2"
        shift 2
        ;;
    -f | --fuzzer)
        fuzzer="$2"
        shift 2
        ;;
    --generator)
        generator="$2"
        shift 2
        ;;
    -t | --target)
        target="$2"
        shift 2
        ;;
    -v | --version)
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
    --cleanup)
        cleanup=1
        shift 1
        ;;
    *)
        # echo "Usage: run.sh -t TARGET -f FUZZER -v VERSION [--times TIMES, --timeout TIMEOUT]"
        break
        ;;
    esac
done

if [[ -n "$generator" && "$fuzzer" != "ft" && "$fuzzer" != "pingu" ]]; then
    log_error "[!] Argument --generator is only allowed when --fuzzer is ft or pingu"
    exit 1
fi

times=${times:-"1"}
protocol=${target%/*}
impl=${target##*/}
# image_name=$(echo "pingu-$fuzzer-$protocol-$impl:$impl_version" | tr 'A-Z' 'a-z')
if [[ -z "$generator" ]]; then
    image_name=$(echo "pingu-${fuzzer}-${protocol}-${impl}:${version:-latest}" | tr 'A-Z' 'a-z')
    container_name="pingu-${fuzzer}-${protocol}-${impl}"
else
    image_name=$(echo "pingu-${fuzzer}-${generator}-${protocol}-${impl}:${version:-latest}" | tr 'A-Z' 'a-z')
    container_name="pingu-${fuzzer}-${generator}-${protocol}-${impl}"
fi

image_id=$(docker images -q "$image_name")
if [[ -n "$image_id" ]]; then
    log_success "[+] Using docker image: $image_name"
else
    log_error "[!] Docker image not found: $image_name"
    exit 1
fi

log_success "[+] Ready to launch image: $image_id"
cids=()
for i in $(seq 1 $times); do
    cmd="docker run -it \
        --cap-add=SYS_ADMIN \
        -v .:/home/user/profuzzbench
        --mount type=tmpfs,destination=/tmp,tmpfs-mode=777 \
        --ulimit msgqueue=2097152000 \
        --shm-size=64G \
        --name $container_name-$i \
        $image_name \
        /bin/bash -c \"bash /home/user/profuzzbench/scripts/dispatch.sh $target run $fuzzer $timeout\""
    echo "$cmd"
    id=$(eval $cmd)
    log_success "[+] Launch docker container: $i"
    cids+=(${id::12}) # store only the first 12 characters of a container ID
done

dlist="" # docker list
for id in ${cids[@]}; do
    dlist+=" ${id}"
done

# wait until all these dockers are stopped
log_success "[+] Fuzzing in progress ..."
log_success "[+] Waiting for the following containers to stop: ${dlist}"
docker wait ${dlist} >/dev/null

index=1
for id in ${cids[@]}; do
    log_success "[+] Pulling fuzzing results from ${id}"
    ts=$(date +%s)
    docker cp ${id}:/home/user/target/${fuzzer}/output.tar.gz ${output}/out-${fuzzer}-${protocol}-${impl}-${impl_version}-${index}-${ts}.tar.gz >/dev/null
    if [ ! -z "$cleanup" ]; then
        docker rm ${id} >/dev/null
        log_success "[+] Container $id deleted"
    fi
    index=$((index+1))
done