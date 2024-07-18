#!/usr/bin/env bash

set -eu
set -o pipefail
cd $(dirname $0)
cd ..

function in_subshell() {
    (
        echo "[+] Running in subshell: $@"
        $@
    )
}

function check_config_exported_functions() {
    local failed=0
    for fn_name in "get_source install_dependencies build_pingu build_aflnet build_stateafl build_sgfuzz build_gcov build_vanilla"; do
        if ! type $fn_name > /dev/null; then
            echo "[!] Target config does not define function $fn_name"
            failed=1
        fi
    done
    if [[ $failed -ne 0 ]]; then
        echo "[!] Config check failed! Please fix your config."
        exit 1
    fi
}

if [[ $# -lt 1 ]]; then
    echo "[!] Not enough arguments! TODO: <path> [mode]"
    echo "[!] <path>: TLS/openssl etc."
    exit 1
fi

path=$1
if [[ ! -d "$path" ]]; then
    echo "[!] Invalid directory: $path"
    exit 1
fi

cfg_path="$path/config.sh"
if [[ ! -f "$cfg_path" ]]; then
    echo "[!] Config could not be found at: $cfg_path"
    exit 1
fi

source $cfg_path
check_config_exported_functions

cd $HOME
mode=${2-"all"}
shift 2
case $mode in
    src)
        in_subshell get_source "$@"
    ;;
    deps)
        in_subshell install_dependencies
    ;;
    pingu)
        # Pingu is the name of my fuzzer :)
        in_subshell build_pingu
    ;;
    aflnet)
        in_subshell build_aflnet
    ;;
    stateafl)
        # StateAFL: https://github.com/stateafl/stateafl
        in_subshell build_stateafl
    ;;
    sgfuzz)
        # SGFuzz: https://github.com/bajinsheng/SGFuzz
        # The configuration steps could also be referenced by https://github.com/fuzztruction/fuzztruction-net/blob/main/Dockerfile
        in_subshell build_sgfuzz
    ;;
    vanilla)
        # Build vanilla version
        # Vanilla means the true original version, without any instrumentation, hooking and analysis.
        in_subshell build_vanilla
    ;;
    gcov)
        # Build the gcov version, which is used to be computed coverage upon.
        in_subshell build_gcov
    ;;
    all)
        in_subshell get_source || true
        in_subshell install_dependencies || true
        in_subshell build_pingu || true
        in_subshell build_aflnet || true
        in_subshell build_stateafl || true
        in_subshell build_sgfuzz || true
        in_subshell build_gcov || true
        in_subshell build_vanilla || true
    ;;
    *)
        echo "[!] Invalid mode $mode"
        exit 1
    ;;
esac