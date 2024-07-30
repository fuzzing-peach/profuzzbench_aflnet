#!/usr/bin/env bash

set -eu

function checkout {
    mkdir -p repo
    git clone https://gitee.com/sz_abundance/openssl.git repo/openssl
    pushd repo/openssl > /dev/null
    git checkout "$@"
    git apply ${HOME}/fuzztruction/fuzztruction-experiments/comparison-with-state-of-the-art/binaries/networked/openssl/fuzzing.patch
    popd > /dev/null
}

function replay {
    timeout -k 0 3s ./apps/openssl s_server \
        -cert ${HOME}/profuzzbench/test.fullchain.pem \
        -key ${HOME}/profuzzbench/test.key.pem \
        -accept 4433 >/dev/null 2>&1 &
    ${HOME}/aflnet/aflnet-replay $1 TLS 4433 100 >/dev/null 2>&1
}

function install_dependencies {
    echo "No dependencies"
}

function build_aflnet {
    mkdir -p target/aflnet
    rm -rf target/aflnet/*
    cp -r repo/openssl target/aflnet/openssl
    pushd target/aflnet/openssl > /dev/null

    export CC=${HOME}/aflnet/afl-clang-fast
    export CXX=${HOME}/aflnet/afl-clang-fast++
    # --with-rand-seed=none only will raise: entropy source strength too weak
    # mentioned by: https://github.com/openssl/openssl/issues/20841
    # see https://github.com/openssl/openssl/blob/master/INSTALL.md#seeding-the-random-generator for selectable options for --with-rand-seed=X
    export CFLAGS="-O3 -g -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION -fsanitize=address"
    export CXXFLAGS="-O3 -g -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION -fsanitize=address"

    ./config --with-rand-seed=devrandom no-shared no-threads no-tests no-asm no-cached-fetch no-async enable-asan
    bear -- make -j

    rm -rf fuzz
    rm -rf test
    rm -rf .git

    popd > /dev/null
}

function run_aflnet {
    timeout=$1
    outdir=${HOME}/target/aflnet/output
    indir=${HOME}/profuzzbench/subjects/TLS/OpenSSL/in-tls
    pushd ${HOME}/target/aflnet/openssl >/dev/null

    mkdir -p $outdir
    rm -rf $outdir/*

    export AFL_SKIP_CPUFREQ=1
    export AFL_PRELOAD=libfake_random.so
    export FAKE_RANDOM=1

    timeout -k 0 --preserve-status $timeout \
        ${HOME}/aflnet/afl-fuzz -d -i $indir \
        -o $outdir -N tcp://127.0.0.1/4433 \
        -P TLS -D 10000 -q 3 -s 3 -E -K -R -W 50 -m none \
        ./apps/openssl s_server \
        -cert ${HOME}/profuzzbench/test.fullchain.pem \
        -key ${HOME}/profuzzbench/test.key.pem \
        -accept 4433 -debug

    list_cmd="ls -1 ${outdir}/replayable-queue/id* | tr '\n' ' ' | sed 's/ $//'"
    pushd ${HOME}/target/gcov/openssl >/dev/null
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
    mkdir -p target/stateafl
    rm -rf target/stateafl/*
    cp -r repo/openssl target/stateafl/openssl
    pushd target/stateafl/openssl > /dev/null

    export AFL_SKIP_CPUFREQ=1
    export CC=${HOME}/stateafl/afl-clang-fast
    export CXX=${HOME}/stateafl/afl-clang-fast++
    export CFLAGS="-O3 -g -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION -DFT_FUZZING -DFT_CONSUMER -fsanitize=address"
    export CXXFLAGS="-O3 -g -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION -DFT_FUZZING -DFT_CONSUMER -fsanitize=address"

    ./config --with-rand-seed=devrandom no-shared no-threads no-tests no-asm no-cached-fetch no-async enable-asan
    bear -- make -j

    rm -rf fuzz
    rm -rf test
    rm -rf .git

    popd > /dev/null
}

function build_sgfuzz {
    echo "Not implemented"
}

function build_pingu {
    echo "Not implemented"
}

function build_ft_generator {
    mkdir -p target/ft/generator
    rm -rf target/ft/generator/*
    cp -r repo/openssl target/ft/generator/openssl
    pushd target/ft/generator/openssl >/dev/null

    export FT_CALL_INJECTION=1
    export FT_HOOK_INS=branch,load,store,select,switch
    export CC=${HOME}/fuzztruction/generator/pass/fuzztruction-source-clang-fast
    export CXX=${HOME}/fuzztruction/generator/pass/fuzztruction-source-clang-fast++
    export CFLAGS="-O3 -g -DNDEBUG -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION -DFT_FUZZING -DFT_GENEARTOR"
    export CXXFLAGS="-O3 -DNDEBUG -g -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION -DFT_FUZZING -DFT_GENEARTOR"

    ./config --with-rand-seed=devrandom no-shared no-threads no-tests no-asm no-cached-fetch no-async enable-asan
    LDCMD=${HOME}/fuzztruction/generator/pass/fuzztruction-source-clang-fast bear -- make -j

    rm -rf fuzz
    rm -rf test
    rm -rf .git

    popd > /dev/null
}

function build_ft_consumer {
    mkdir -p target/ft/consumer
    rm -rf target/ft/consumer/*
    cp -r repo/openssl target/ft/consumer/openssl
    pushd target/ft/consumer/openssl >/dev/null

    export AFL_PATH=${HOME}/fuzztruction/consumer/aflpp-consumer
    export CC=${AFL_PATH}/afl-clang-fast
    export CXX=${AFL_PATH}/afl-clang-fast++
    export CFLAGS="-O3 -g -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION -DFT_FUZZING -DFT_CONSUMER -fsanitize=address"
    export CXXFLAGS="-O3 -g -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION -DFT_FUZZING -DFT_CONSUMER -fsanitize=address"
    # export AFL_LLVM_LAF_SPLIT_SWITCHES=1
    # export AFL_LLVM_LAF_TRANSFORM_COMPARES=1
    # export AFL_LLVM_LAF_SPLIT_COMPARES=1

    ./config --with-rand-seed=none no-shared no-threads no-tests no-asm no-cached-fetch no-async enable-asan
    bear -- make -j

    rm -rf fuzz
    rm -rf test
    rm -rf .git

    popd > /dev/null
}

function build_gcov {
    mkdir -p target/gcov
    rm -rf target/gcov/*
    cp -r repo/openssl target/gcov/openssl
    pushd target/gcov/openssl >/dev/null

    export CFLAGS="-fprofile-arcs -ftest-coverage"
    export LDFLAGS="-fprofile-arcs -ftest-coverage"

    ./config --with-rand-seed=devrandom no-shared no-threads no-tests no-asm no-cached-fetch no-async
    make -j

    popd > /dev/null
}

function build_vanilla {
    mkdir -p target/vanilla
    rm -rf target/vanilla/*
    cp -r repo/openssl target/vanilla/openssl
    pushd target/vanilla/openssl >/dev/null

    ./config --with-rand-seed=devrandom no-shared no-threads no-tests no-asm no-cached-fetch no-async 
    make -j

    popd > /dev/null
}