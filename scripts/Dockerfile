FROM pingu-env:latest

USER ubuntu
WORKDIR /home/ubuntu/profuzzbench

ARG FUZZER
ARG TARGET
ENV FUZZER=${FUZZER}
ENV TARGET=${TARGET}

RUN bash scripts/dispatch.sh subjects/${TARGET} src
RUN bash scripts/dispatch.sh subjects/${TARGET} deps
RUN bash scripts/dispatch.sh subjects/${TARGET} gcov
RUN bash scripts/dispatch.sh subjects/${TARGET} ${FUZZER}