FROM pingu-env:latest

USER user
ENV HOME=/home/user

ARG FUZZER
ARG TARGET
ARG VERSION
ARG ARGS
ENV FUZZER=${FUZZER}
ENV TARGET=${TARGET}
ENV VERSION=${VERSION}
ENV ARGS=${ARGS}
ENV TERM=xterm

# RUN pwd
RUN --mount=type=bind,source=.,target=/home/user/profuzzbench\
    bash ${HOME}/profuzzbench/scripts/dispatch.sh ${TARGET} checkout ${VERSION} && \
    bash ${HOME}/profuzzbench/scripts/dispatch.sh ${TARGET} build deps && \
    bash ${HOME}/profuzzbench/scripts/dispatch.sh ${TARGET} build gcov && \
    bash ${HOME}/profuzzbench/scripts/dispatch.sh ${TARGET} build ${FUZZER} ${ARGS}
# RUN scripts/dispatch.sh ${TARGET} build vanilla