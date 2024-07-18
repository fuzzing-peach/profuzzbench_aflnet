#!/usr/bin/env bash

set -e

function get_source {
    mkdir -p src
    pushd src > /dev/null
    git clone https://github.com/wolfSSL/wolfssl.git
    cd wolfssl
    if [[ -n "$1" ]]; then
        git checkout "$1"
    fi
    popd > /dev/null
}

function build_aflnet {
    mkdir -p aflnet
    rm -rf aflnet/*
    cp -r src/wolfssl aflnet/
    pushd aflnet/wolfssl > /dev/null

    export AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1
    export AFL_SKIP_CPUFREQ=1
    export AFL_NO_AFFINITY=1
    export CC=afl-clang-fast 
    export AFL_USE_ASAN=1

    ./configure --enable-static --enable-shared=no
    make examples/server/server -j

    popd > /dev/null
}

function run_aflnet {
    echo "Not implemented"
}

function build_stateafl {
    mkdir -p stateafl
    rm -rf stateafl/*
    cp -r src/openssl stateafl/
    pushd stateafl/openssl > /dev/null

    # TODO:

    popd > /dev/null
}

function build_gcov {
    mkdir -p gcov
    rm -rf gcov/*
    cp -r src/wolfssl gcov/
    pushd gcov/wolfssl > /dev/null

    export CFLAGS="-fprofile-arcs -ftest-coverage"
    export LDFLAGS="-fprofile-arcs -ftest-coverage"

    ./configure --enable-static --enable-shared=no
    make examples/server/server -j

    popd > /dev/null
}

function build_vanilla {
    mkdir -p vanilla
    rm -rf vanilla/*
    cp -r src/wolfssl vanilla/
    pushd vanilla/wolfssl > /dev/null

    ./configure --enable-static --enable-shared=no
    make examples/server/server -j

    popd > /dev/null
}

function build_pingu {
    echo "Not implemented"
}

function build_sgfuzz {
    echo "Not implemented"
}

function install_dependencies {
    echo "Not implemented"
}