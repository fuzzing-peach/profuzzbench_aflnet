#!/usr/bin/env bash
function build_sgfuzz {
    mkdir -p target/sgfuzz
    rm -rf target/sgfuzz/*
    cp -r repo/live555 target/sgfuzz/live555
    pushd target/sgfuzz/live555 >/dev/null

    patch -p1 < "${HOME}/sgfuzz/example/live555/fuzzing.patch"

    sed -i "s/int main(/extern \"C\" int HonggfuzzNetDriver_main(/g" testProgs/testOnDemandRTSPServer.cpp
    cp "${HOME}/sgfuzz/example/live555/blocked_variables.txt" ./

    python3 "${HOME}/sgfuzz/sanitizer/State_machine_instrument.py" ./ -b blocked_variables.txt

    ./genMakefiles linux-no-openssl && \
    make C_COMPILER=clang-10 CPLUSPLUS_COMPILER=clang++-10 CFLAGS="-g -fsanitize=fuzzer-no-link -fsanitize=address" CXXFLAGS="-g -fsanitize=fuzzer-no-link -fsanitize=address" \
        LINK="clang++-10 -fsanitize=fuzzer-no-link -fsanitize=address -o " all
    cd testProgs
    clang++-10 -fsanitize=fuzzer-no-link -fsanitize=address -o testOnDemandRTSPServer -L.\
        testOnDemandRTSPServer.o announceURL.o ../liveMedia/libliveMedia.a ../groupsock/libgroupsock.a ../BasicUsageEnvironment/libBasicUsageEnvironment.a ../UsageEnvironment/libUsageEnvironment.a -lsFuzzer -lhfnetdriver -lhfcommon
    echo "done!"
}

function run_sgfuzz {
    timeout=$1
    outdir=/tmp/fuzzing-output
    indir=${HOME}/profuzzbench/subjects/RTSP/Live555/in-rtsp
    pushd ${HOME}/target/sgfuzz/live555
    
    mkdir -p $outdir
    rm -rf $outdir/*

    SGFuzzPara="-close_fd_mask=3 -shrink=1 -print_full_coverage=1 -check_input_sha1=1 -reduce_inputs=1\
                -dict=${HOME}/profuzzbench/subjects/RTSP/Live555/rtsp.dict\
                -reload=30 -only_ascii=1 -print_final_stats=1 -detect_leaks=0 ${outdir} ${indir}"

    ASAN_OPTIONS=alloc_dealloc_mismatch=0 ./testOnDemandRTSPServer ${SGFuzzPara}
}