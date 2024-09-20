ARG BASE_IMAGE=pingu-env:latest

FROM ${BASE_IMAGE}

USER user
ENV HOME=/home/user

ARG FUZZER
ARG TARGET
ARG VERSION
ARG GENERATOR
ARG MAKE_OPT="-j8"
ENV MAKE_OPT=${MAKE_OPT}
ARG CARGO_BUILD_JOBS="8"
ENV CARGO_BUILD_JOBS=${CARGO_BUILD_JOBS}
ENV FUZZER=${FUZZER}
ENV TARGET=${TARGET}
ENV VERSION=${VERSION}
ENV GENERATOR=${GENERATOR}
ENV TERM=xterm
ENV no_proxy=localhost,127.0.0.1

# RUN pwd
RUN --mount=type=bind,source=.,target=/home/user/profuzzbench \
    bash ${HOME}/profuzzbench/scripts/dispatch.sh ${TARGET} build deps
RUN --mount=type=bind,source=.,target=/home/user/profuzzbench \
    bash ${HOME}/profuzzbench/scripts/dispatch.sh ${TARGET} checkout ${VERSION}
RUN --mount=type=bind,source=.,target=/home/user/profuzzbench \
    bash ${HOME}/profuzzbench/scripts/dispatch.sh ${TARGET} build gcov
RUN --mount=type=bind,source=.,target=/home/user/profuzzbench \
    bash ${HOME}/profuzzbench/scripts/dispatch.sh ${TARGET} build ${FUZZER}