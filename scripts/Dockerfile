FROM pingu-env:latest

USER ubuntu
WORKDIR /home/ubuntu/profuzzbench

ARG FUZZER
ARG TARGET
ARG VERSION
ENV FUZZER=${FUZZER}
ENV TARGET=${TARGET}
ENV VERSION=${VERSION}
ENV TERM=xterm

RUN scripts/dispatch.sh subjects/${TARGET} build deps
RUN scripts/dispatch.sh subjects/${TARGET} build vanilla
RUN scripts/dispatch.sh subjects/${TARGET} build gcov
RUN scripts/dispatch.sh subjects/${TARGET} build ${FUZZER}