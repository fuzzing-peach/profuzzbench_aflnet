FROM pingu-env:latest

USER ubuntu
WORKDIR /home/ubuntu

ARG FUZZER
ARG TARGET
ENV FUZZER=${FUZZER}
ENV TARGET=${TARGET}

RUN bash scripts/dispatch.sh ${TARGET} src
RUN bash scripts/dispatch.sh ${TARGET} deps
RUN bash scripts/dispatch.sh ${TARGET} ${FUZZER}