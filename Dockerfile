FROM alpine:latest

WORKDIR /rssh

RUN RSSH_VERSION=2.3.4-r0 && \
    RSYNC_VERSION=3.1.3-r1 && \
    SSH_VERSION=7.9_p1-r4 && \
    apk --no-cache add rssh=${RSSH_VERSION} rsync=${RSYNC_VERSION} openssh-server=${SSH_VERSION} && \
    RSSH_VERSION= && \
    RSYNC_VERSION= && \
    SSH_VERSION=

ENV VOL_HOME=/rssh/home
ENV VOL_CFG=/rssh/cfg

VOLUME ["${VOL_HOME}", "${VOL_CFG}"]

EXPOSE 22

COPY ["init.sh", "./"]
COPY ["sshd_config", "/etc/ssh/"]
COPY ["rssh.conf", "/etc"]

ENTRYPOINT ["./init.sh"]
CMD ["sshd"]
