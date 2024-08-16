#!/usr/bin/env bash

cd $(dirname $0)
cd ..
source scripts/utils.sh

function in_subshell() {
    (
        cd "$HOME"
        echo "[+] Running in subshell: $@"
        $@
    )
}

if [[ $# -lt 1 ]]; then
    echo "[!] Not enough arguments! TODO: <path> [mode]"
    echo "[!] <path>: TLS/openssl etc."
    exit 1
fi

target=$1
if [[ ! -d "subjects/${target}" ]]; then
    echo "[!] Invalid target: $target"
    exit 1
fi

target_config="subjects/$target/config.sh"
if [[ ! -f "$target_config" ]]; then
    echo "[!] Config could not be found at: $target_config"
    exit 1
fi

cmd=${2-"build"}
# cmd is checkout
case $cmd in
checkout)
    source $target_config
    shift 2
    in_subshell checkout "$@"
    exit 0
    ;;
*) ;;
esac

# cmd is build/run
mode=${3-"all"}
shift 3
case $mode in
deps)
    source $target_config
    in_subshell install_dependencies "$@"
    ;;
pingu)
    # Pingu is the name of my fuzzer :)
    if [[ "$cmd" == "build" ]]; then
        (
            # build consumer
            source $target_config
            # ignore the ${GENERATOR}
            in_subshell build_pingu_consumer "${@:2}"
        )
        (
            # build generator
            if [[ -n $1 ]]; then
                generator=${target%/*}/$1
            else
                generator=${target}
            fi
            source "subjects/$generator/config.sh"
            in_subshell build_pingu_generator "${@:2}"
        )
    else
        # run generator-consumer
        source $target_config
        # run_pingu $timeout $generator
        in_subshell run_pingu "$@"
    fi
    ;;
ft)
    # FT-Net: https://github.com/fuzztruction/fuzztruction-net
    # args: scripts/dispatch.sh ${TARGET} build ft ${GENERATOR}
    # when ${GENERATOR} is not specified, it is treated the same as ${TARGET}
    # ${GENERATOR} is the implmentation name like OpenSSL
    if [[ "$cmd" == "build" ]]; then
        (
            # build consumer
            source $target_config
            # ignore the ${GENERATOR}
            in_subshell build_ft_consumer "${@:2}"
        )
        (
            # build generator
            if [[ -n $1 ]]; then
                generator=${target%/*}/$1
            else
                generator=${target}
            fi
            source "subjects/$generator/config.sh"
            in_subshell build_ft_generator "${@:2}"
        )
    else
        # run generator-consumer
        source $target_config
        # run_ft $timeout $generator
        in_subshell run_ft "$@"
    fi
    ;;
aflnet)
    source $target_config
    in_subshell "$cmd"_aflnet "$@"
    ;;
stateafl)
    # StateAFL: https://github.com/stateafl/stateafl
    source $target_config
    in_subshell "$cmd"_stateafl "$@"
    ;;
sgfuzz)
    # SGFuzz: https://github.com/bajinsheng/SGFuzz
    # The configuration steps could also be referenced by https://github.com/fuzztruction/fuzztruction-net/blob/main/Dockerfile
    source $target_config
    in_subshell "$cmd"_sgfuzz "$@"
    ;;
vanilla)
    # Build vanilla version
    # Vanilla means the true original version, without any instrumentation, hooking and analysis.
    source $target_config
    in_subshell build_vanilla "$@"
    ;;
gcov)
    # Build the gcov version, which is used to be computed coverage upon.
    source $target_config
    in_subshell build_gcov "$@"
    ;;
all)
    echo "[!] Not implemented for 'all'"
    ;;
*)
    echo "[!] Invalid mode $mode"
    exit 1
    ;;
esac
