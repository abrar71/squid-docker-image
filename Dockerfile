ARG SQUID_VERSION=7.8
ARG SQUID_TAG=SQUID_7_8
ARG SQUID_TARBALL_SHA256=52cd716f568faccbd3e237d77fd3518cbfe1548dfa2ebd8871b5a112e8ab0063
ARG BASE_IMAGE=debian:trixie-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2

FROM --platform=$TARGETPLATFORM ${BASE_IMAGE} AS builder

ARG SQUID_VERSION
ARG SQUID_TAG
ARG SQUID_TARBALL_SHA256

RUN apt-get update && apt-get install -y --no-install-recommends \
    autoconf \
    automake \
    bison \
    ca-certificates \
    curl \
    flex \
    g++ \
    libltdl-dev \
    libtool \
    libtool-bin \
    libssl-dev \
    m4 \
    make \
    perl \
    pkg-config \
    tar \
    xz-utils \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /build

RUN curl -fsSL -o squid.tar.xz \
    "https://github.com/squid-cache/squid/releases/download/${SQUID_TAG}/squid-${SQUID_VERSION}.tar.xz" \
  && echo "${SQUID_TARBALL_SHA256}  squid.tar.xz" | sha256sum -c - \
  && tar -xJf squid.tar.xz \
  && mv "squid-${SQUID_VERSION}" squid

WORKDIR /build/squid

RUN ./configure \
    --prefix=/usr \
    --localstatedir=/var \
    --libexecdir=/usr/lib/squid \
    --datadir=/usr/share/squid \
    --sysconfdir=/etc/squid \
    --with-default-user=proxy \
    --with-logdir=/var/log/squid \
    --with-pidfile=/run/squid.pid \
    --with-openssl \
    --enable-ssl \
    --disable-translation \
  && make -j"$(nproc)" \
  && make install-strip

FROM --platform=$TARGETPLATFORM ${BASE_IMAGE}

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libdb5.3t64 \
    libecap3 \
    libexpat1 \
    libgcc-s1 \
    libgnutls30t64 \
    libnetfilter-conntrack3 \
    libssl3t64 \
    libstdc++6 \
    libxml2 \
    logrotate \
  && rm -rf /var/lib/apt/lists/* \
  && getent group proxy >/dev/null || groupadd -r proxy \
  && id -u proxy >/dev/null 2>&1 || useradd -r -g proxy -d /var/spool/squid -s /usr/sbin/nologin proxy \
  && mkdir -p /var/spool/squid /var/log/squid /run \
  && chown -R proxy:proxy /var/spool/squid /var/log/squid

COPY --from=builder /usr /usr
COPY --from=builder /etc/squid /etc/squid

EXPOSE 3129

CMD ["/usr/sbin/squid", "-N", "-f", "/etc/squid/squid.conf"]
