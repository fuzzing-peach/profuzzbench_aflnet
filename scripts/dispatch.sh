#!/usr/bin/env bash

set -e
set -o pipefail
cd $(dirname $0)
cd ..
source scripts/utils.sh

function in_subshell() {
    (
        echo "[+] Running in subshell: $@"
        $@
    )
}

function check_config_exported_functions() {
    local failed=0
    for fn_name in "install_dependencies build_pingu build_aflnet build_stateafl build_sgfuzz build_gcov build_vanilla"; do
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
cmd=${2-"build"}
mode=${3-"all"}
shift 3
case $mode in
    deps)
        in_subshell install_dependencies "$@"
    ;;
    pingu)
        # Pingu is the name of my fuzzer :)
        in_subshell "$cmd"_pingu "$@"
    ;;
    aflnet)
        in_subshell "$cmd"_aflnet "$@"
    ;;
    stateafl)
        # StateAFL: https://github.com/stateafl/stateafl
        in_subshell "$cmd"_stateafl "$@"
    ;;
    sgfuzz)
        # SGFuzz: https://github.com/bajinsheng/SGFuzz
        # The configuration steps could also be referenced by https://github.com/fuzztruction/fuzztruction-net/blob/main/Dockerfile
        in_subshell "$cmd"_sgfuzz "$@"
    ;;
    vanilla)
        # Build vanilla version
        # Vanilla means the true original version, without any instrumentation, hooking and analysis.
        in_subshell build_vanilla "$@"
    ;;
    gcov)
        # Build the gcov version, which is used to be computed coverage upon.
        in_subshell build_gcov "$@"
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