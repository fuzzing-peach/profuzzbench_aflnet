#!/usr/bin/env bash

set -e

function build_aflnet {
    mkdir -p target/aflnet
    rm -rf target/aflnet/*
    cp -r repo/wolfssl target/aflnet/
    pushd target/aflnet/wolfssl >/dev/null

    export AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1
    export AFL_SKIP_CPUFREQ=1
    export AFL_NO_AFFINITY=1
    export CC=$HOME/aflnet/afl-clang-fast
    export AFL_USE_ASAN=1

    ./autogen.sh
    ./configure --enable-static --enable-shared=no
    make examples/server/server -j

    popd >/dev/null

    cp profuzzbench/test.fullchain.pem target/aflnet/wolfssl
    cp profuzzbench/test.key.pem target/aflnet/wolfssl
}

function replay {
    export LD_PRELOAD=libfake_random.so
    export FAKE_RANDOM=1
    timeout -k 0 3s ./examples/server/server -c test.fullchain.pem -k test.key.pem -e -p 4433 >/dev/null 2>&1 &
    $HOME/aflnet/aflnet-replay $1 TLS 4433 100 >/dev/null 2>&1
}

function run_aflnet {
    timeout=$1
    outdir=${HOME}/target/aflnet/output
    indir=${HOME}/profuzzbench/subjects/TLS/OpenSSL/in-tls
    pushd ${HOME}/target/aflnet/wolfssl >/dev/null

    mkdir -p $outdir
    rm -rf $outdir/*

    export AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1
    export AFL_SKIP_CPUFREQ=1
    export AFL_NO_AFFINITY=1
    export AFL_PRELOAD=libfake_random.so
    export FAKE_RANDOM=1

    timeout -k 0 --preserve-status $timeout \
        $HOME/aflnet/afl-fuzz -d -i $indir \
        -o $outdir -N tcp://127.0.0.1/4433 \
        -P TLS -D 10000 -q 3 -s 3 -E -K -R -W 100 -m none \
        ./examples/server/server -c test.fullchain.pem -k test.key.pem -e -p 4433

    list_cmd="ls -1 ${outdir}/replayable-queue/id* | tr '\n' ' ' | sed 's/ $//'"
    pushd $HOME/target/gcov/wolfssl >/dev/null
    compute_coverage replay "$list_cmd" 1 ${outdir}/coverage.csv

    gcovr -r . --html --html-details -o index.html
    mkdir $outdir/cov_html/
    cp *.html $outdir/cov_html/

    cd $outdir/..
    tar -zcvf output.tar.gz output

    popd >/dev/null
    popd >/dev/null
}

function build_stateafl {
    mkdir -p stateafl
    rm -rf stateafl/*
    cp -r src/wolfssl stateafl/
    pushd stateafl/wolfssl >/dev/null

    # TODO:

    popd >/dev/null
}

function build_gcov {
    mkdir -p target/gcov
    rm -rf target/gcov/*
    cp -r repo/wolfssl target/gcov/
    pushd target/gcov/wolfssl >/dev/null

    ./autogen.sh

    export CFLAGS="-fprofile-arcs -ftest-coverage"
    export CXXFLAGS="-fprofile-arcs -ftest-coverage"
    export CPPFLAGS="-fprofile-arcs -ftest-coverage"
    export LDFLAGS="-fprofile-arcs -ftest-coverage"

    ./configure --enable-static --enable-shared=no
    make examples/server/server -j

    rm -rf a-conftest.gcno

    popd >/dev/null

    cp profuzzbench/test.fullchain.pem target/gcov/wolfssl
    cp profuzzbench/test.key.pem target/gcov/wolfssl
}

function build_vanilla {
    mkdir -p target/vanilla
    rm -rf target/vanilla/*
    cp -r repo/wolfssl target/vanilla/
    pushd target/vanilla/wolfssl >/dev/null

    ./autogen.sh
    ./configure --enable-static --enable-shared=no
    make examples/server/server -j

    popd >/dev/null

    cp profuzzbench/test.fullchain.pem target/vanilla/wolfssl
    cp profuzzbench/test.key.pem target/vanilla/wolfssl
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
