FROM pingu-env:latest

USER ubuntu
WORKDIR /home/ubuntu/profuzzbench

ARG FUZZER
ARG TARGET
ARG VERSION
ENV FUZZER=${FUZZER}
ENV TARGET=${TARGET}
ENV VERSION=${VERSION}

RUN bash scripts/dispatch.sh subjects/${TARGET} src ${VERSION}
# RUN bash scripts/dispatch.sh subjects/${TARGET} deps
# RUN bash scripts/dispatch.sh subjects/${TARGET} gcov
# RUN bash scripts/dispatch.sh subjects/${TARGET} ${FUZZER}