FROM pingu-env:latest

USER user
WORKDIR /home/user/profuzzbench

ARG FUZZER
ARG TARGET
ARG VERSION
ARG ARGS
ENV FUZZER=${FUZZER}
ENV TARGET=${TARGET}
ENV VERSION=${VERSION}
ENV ARGS=${ARGS}
ENV TERM=xterm

RUN pwd
RUN scripts/dispatch.sh ${TARGET} checkout ${VERSION}
RUN scripts/dispatch.sh ${TARGET} build deps
RUN scripts/dispatch.sh ${TARGET} build vanilla
RUN scripts/dispatch.sh ${TARGET} build gcov
RUN scripts/dispatch.sh ${TARGET} build ${FUZZER} ${ARGS}