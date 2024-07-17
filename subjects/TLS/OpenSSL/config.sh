#!/usr/bin/env bash

set -eu

function get_source {
    mkdir -p src
    pushd src > /dev/null
    git clone https://github.com/openssl/openssl.git
    cd openssl
    if [["$#" -lt 1 && "$1" == "checkout" ]]; then
        shift
        git checkout "$@"
    fi
    popd > /dev/null
}

function install_dependencies {
    echo "No dependencies"
}

function build_aflnet {
    mkdir -p aflnet
    rm -rf aflnet/*
    cp -r src/openssl aflnet/
    pushd aflnet/openssl > /dev/null

    export AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1
    export AFL_SKIP_CPUFREQ=1
    export AFL_NO_AFFINITY=1
    export CC=afl-clang-fast 
    export AFL_USE_ASAN=1 

    ./config no-shared no-threads --with-rand-seed=none
    make include/openssl/configuration.h include/openssl/opensslv.h include/crypto/bn_conf.h include/crypto/dso_conf.h
    make apps/openssl -j

    popd > /dev/null
}

function build_stateafl {
    mkdir -p stateafl
    rm -rf stateafl/*
    cp -r src/openssl stateafl/
    pushd stateafl/openssl > /dev/null

    # TODO:

    popd > /dev/null
}

function build_sgfuzz {
    echo "Not implemented"
}

function build_pingu {
    echo "Not implemented"
}

function build_gcov {
    mkdir -p gcov
    rm -rf gcov/*
    cp -r src/openssl gcov/
    pushd gcov/openssl > /dev/null

    export CFLAGS="-fprofile-arcs -ftest-coverage"
    export LDFLAGS="-fprofile-arcs -ftest-coverage"

    ./config no-shared no-threads --with-rand-seed=none
    make include/openssl/configuration.h include/openssl/opensslv.h include/crypto/bn_conf.h include/crypto/dso_conf.h
    make apps/openssl -j

    popd > /dev/null
}

function build_vanilla {
    mkdir -p vanilla
    rm -rf vanilla/*
    cp -r src/openssl vanilla/
    pushd vanilla/openssl > /dev/null

    ./config no-shared no-threads --with-rand-seed=none
    make include/openssl/configuration.h include/openssl/opensslv.h include/crypto/bn_conf.h include/crypto/dso_conf.h
    make apps/openssl -j

    popd > /dev/null
}