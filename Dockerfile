ARG HARNESS_ALPINE_IMAGE=harness0.harness.io/oci/docker_artifacts/hhi/harnessos-alpine@sha256:aa1f4e2851f202f6fb08e30eace3d94298b610aceb381d2df92815f536fd516f
FROM ${HARNESS_ALPINE_IMAGE} AS build

RUN apk add --no-cache msgpack-c ncurses libevent openssl zlib curl

RUN apk add --no-cache \
	autoconf \
	automake \
	cmake \
	gcc \
	git \
	libevent-dev \
	linux-headers \
	make \
	pkgconf-dev \
	msgpack-c-dev \
	ncurses-dev \
	openssl-dev \
	zlib-dev \
	curl-dev \
	wget

RUN apk add --no-cache libssh-dev

RUN mkdir -p /src/tmate-ssh-server
COPY . /src/tmate-ssh-server

RUN set -ex; \
	cd /src/tmate-ssh-server; \
	./autogen.sh; \
	./configure --prefix=/usr CFLAGS="-D_GNU_SOURCE"; \
	make -j "$(nproc)"; \
	make install

### Minimal run-time image
ARG HARNESS_ALPINE_IMAGE
FROM ${HARNESS_ALPINE_IMAGE}

RUN apk add --no-cache \
	bash \
	gdb \
	libevent \
	libssh \
	msgpack-c-libs \
	ncurses \
	openssl \
	zlib \
	curl

COPY --from=build /usr/bin/tmate-ssh-server /usr/bin/

# TODO not run as root. Instead, use capabilities.

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENV LC_ALL=C.utf8

EXPOSE 2200
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
