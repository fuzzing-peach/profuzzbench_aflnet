


function checkout {
    mkdir -p repo
    git clone https://github.com/rgaufman/live555.git  repo/rtsp
    
    pushd repo/rtsp >/dev/null
   
    
    popd >/dev/null
}

function replay {
    # the process launching order is confusing.
    ${HOME}/aflnet/aflnet-replay $1 RTSP 8554 100 &
    LD_PRELOAD=libgcov_preload.so:libfake_random.so FAKE_RANDOM=1 \
        timeout -k 1s 3s  ${HOME}/target/aflnet/rtsp/testProgs/testOnDemandRTSPServer 8554 \
       
   
    wait
}

function build_aflnet {
    mkdir -p target/aflnet
    rm -rf target/aflnet/*
    cp -r repo/rtsp target/aflnet/rtsp
    pushd target/aflnet/rtsp >/dev/null

    export CC=${HOME}/aflnet/afl-clang-fast
    export CXX=${HOME}/aflnet/afl-clang-fast++
    # --with-rand-seed=none only will raise: entropy source strength too weak
    # mentioned by: https://github.com/openssl/openssl/issues/20841
    # see https://github.com/openssl/openssl/blob/master/INSTALL.md#seeding-the-random-generator for selectable options for --with-rand-seed=X
    export CFLAGS="-O3 -g -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION -DFT_FUZZING -DFT_CONSUMER"
    export CXXFLAGS="-O3 -g -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION -DFT_FUZZING -DFT_CONSUMER"
    sed -i "s@^C_COMPILER.*@C_COMPILER = $CC@g" config.linux
    sed -i "s@^CPLUSPLUS_COMPILER.*@CPLUSPLUS_COMPILER = $CXX@g" config.linux
    sed -i "s@^LINK =.*@LINK = $CXX -o@g" config.linux
    
  
    ./genMakefiles linux
    make -j
    
    popd >/dev/null
}


function run_aflnet {
    timeout=$1
    outdir=/tmp/fuzzing-output
    indir=${HOME}/profuzzbench/subjects/RTSP/Live555/in-rtsp
    pushd ${HOME}/target/aflnet/rtsp >/dev/null

    mkdir -p $outdir
    rm -rf $outdir/*

    export AFL_SKIP_CPUFREQ=1
    export AFL_PRELOAD=libfake_random.so
    export FAKE_RANDOM=1 # fake_random is not working with -DFT_FUZZING enabled
    export ASAN_OPTIONS="abort_on_error=1:symbolize=0:detect_leaks=0:handle_abort=2:handle_segv=2:handle_sigbus=2:handle_sigill=2:detect_stack_use_after_return=0:detect_odr_violation=0"
    echo abc
    timeout -k 0 --preserve-status $timeout \
        ${HOME}/aflnet/afl-fuzz -d -i $indir \
        -o $outdir -N tcp://127.0.0.1/8554 \
        -P RTSP -D 10000 -q 3 -s 3 -E -K -R -W 50  -m none \
        ${HOME}/target/aflnet/rtsp/testProgs/testOnDemandRTSPServer 8554
        
    
    list_cmd="ls -1 ${outdir}/replayable-queue/id* | tr '\n' ' ' | sed 's/ $//'"
    cd ${HOME}/target/gcov/consumer/rtsp

    compute_coverage replay "$list_cmd" 1 ${outdir}/coverage.csv
    mkdir -p ${outdir}/cov_html
    gcovr -r . --html --html-details -o ${outdir}/cov_html/index.html

    popd >/dev/null
}
function install_dependencies {
    echo "Not implemented"
}
function build_gcov {
    mkdir -p target/gcov/consumer
    rm -rf target/gcov/consumer/*
    cp -r repo/rtsp target/gcov/consumer/rtsp
    pushd target/gcov/consumer/rtsp >/dev/null
    
    export CFLAGS="-fprofile-arcs -ftest-coverage -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION -DFT_FUZZING -DFT_CONSUMER"
    export LDFLAGS="-fprofile-arcs -ftest-coverage"
    ./genMakefiles linux
    make -j4

    
    popd >/dev/null
}