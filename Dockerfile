ARG UVER=23.04
FROM ubuntu:${UVER}

ARG UVER

LABEL maintainer="thomfab"

# install prerequisite debian packages
RUN echo "**** install prerequisite ****" \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        gosu \
        uuid-runtime \
        wget

RUN echo "**** download megacmd ubuntu package ****" \
 && cd /tmp \
 && wget https://mega.nz/linux/repo/xUbuntu_${UVER}/amd64/megacmd-xUbuntu_${UVER}_amd64.deb \
 && echo "**** install megacmd ubuntu package ****" \
 && apt-get install -y "/tmp/megacmd-xUbuntu_${UVER}_amd64.deb" \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/mega-cmd-server"]