# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-alpine:3.21

# set version label
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
ARG WIREGUARD_RELEASE
LABEL build_version="Build-version: ${VERSION} Build-date: ${BUILD_DATE}"
LABEL maintainer="Julien Hauseux <julien.hauseux@gmail.com>"
LABEL \
  org.opencontainers.image.title="NordLynx" \
  org.opencontainers.image.description="A containerized client for NordLynx (NordVPN WireGuard protocol)." \
  org.opencontainers.image.version="${VERSION}" \
  org.opencontainers.image.authors="Julien Hauseux <julien.hauseux@gmail.com>" \
  org.opencontainers.image.vendor="Julien Hauseux" \
  org.opencontainers.image.licenses="GPL-3.0-or-later" \
  org.opencontainers.image.base.name="ghcr.io/linuxserver/baseimage-alpine:3.20" \
  org.opencontainers.image.base.digest="" \
  org.opencontainers.image.created="${BUILD_DATE}" \
  org.opencontainers.image.revision="${VCS_REF}" \
  org.opencontainers.image.ref.name="${VCS_REF}" \
  org.opencontainers.image.url="https://github.com/arkandias/docker-nordlynx" \
  org.opencontainers.image.source="https://github.com/arkandias/docker-nordlynx" \
  org.opencontainers.image.documentation="https://github.com/arkandias/docker-nordlynx/README.md"

RUN \
  if [ -z ${WIREGUARD_RELEASE+x} ]; then \
  WIREGUARD_RELEASE=$(curl -sL "http://dl-cdn.alpinelinux.org/alpine/v3.21/main/x86_64/APKINDEX.tar.gz" | tar -xz -C /tmp \
    && awk '/^P:wireguard-tools$/,/V:/' /tmp/APKINDEX | sed -n 2p | sed 's/^V://'); \
  fi && \
  echo "**** install dependencies ****" && \
  apk add --no-cache \
    bc \
    coredns \
    grep \
    iproute2 \
    iptables \
    iptables-legacy \
    ip6tables \
    iputils \
    kmod \
    libcap-utils \
    libqrencode-tools \
    net-tools \
    openresolv \
    wireguard-tools==${WIREGUARD_RELEASE} && \
  echo "wireguard" >> /etc/modules && \
  cd /sbin && \
  for i in ! !-save !-restore; do \
    rm -rf iptables$(echo "${i}" | cut -c2-) && \
    rm -rf ip6tables$(echo "${i}" | cut -c2-) && \
    ln -s iptables-legacy$(echo "${i}" | cut -c2-) iptables$(echo "${i}" | cut -c2-) && \
    ln -s ip6tables-legacy$(echo "${i}" | cut -c2-) ip6tables$(echo "${i}" | cut -c2-); \
  done && \
  sed -i 's|\[\[ $proto == -4 \]\] && cmd sysctl -q net\.ipv4\.conf\.all\.src_valid_mark=1|[[ $proto == -4 ]] \&\& [[ $(sysctl -n net.ipv4.conf.all.src_valid_mark) != 1 ]] \&\& cmd sysctl -q net.ipv4.conf.all.src_valid_mark=1|' /usr/bin/wg-quick && \
  rm -rf /etc/wireguard && \
  ln -s /config/wg_confs /etc/wireguard && \
  printf "Build-version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version && \
  echo "**** clean up ****" && \
  rm -rf \
    /tmp/*

# add local files
COPY /root /

# ports and volumes
EXPOSE 51820/udp
    
HEALTHCHECK \
  --start-period=30s --start-interval=5s \
  CMD /usr/local/bin/healthcheck
