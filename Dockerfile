ARG FIPS=""
ARG PRIVATE_REGISTRY
ARG VER="1.0.0"
ARG OS="linux"
ARG GOOS="linux"
ARG GOARCH="amd64"
ARG PKG="base-scripts"

ARG GO="1.26"
ARG GOFIPS140_VER="v1.26.0"
ARG BUILDER_IMAGE="golang"
ARG BUILDER_VER="${GO}-alpine"
ARG BUILDER_IMG="${BUILDER_IMAGE}:${BUILDER_VER}"

ARG GOTEMPLATE_VER="5.2.0"
ARG GOTEMPLATE_SRC="https://github.com/hairyhenderson/gomplate/releases/download/v${GOTEMPLATE_VER}/gomplate_${GOOS}-${GOARCH}"

FROM "${BUILDER_IMG}" AS gucci

ARG FIPS
ARG GO
ARG GOFIPS140_VER
ARG GUCCI_REPO="https://github.com/noqcks/gucci.git"
ARG GUCCI_VER="1.9.0"

RUN apk --no-cache add git

ENV SRCPATH="/build/gucci"
ENV GO111MODULE="on"
ENV CGO_ENABLED="0"
RUN mkdir -p "${SRCPATH}" && \
    cd "${SRCPATH}" && \
    if [ -n "${FIPS}" ] ; then \
        export GOFIPS140="${GOFIPS140_VER}" ; \
        echo "🔒 Building a FIPS-hardened ETCD binary (GOFIPS140=${GOFIPS140})" ; \
    fi ; \
    git clone "${GUCCI_REPO}" "." --branch="v${GUCCI_VER}" && \
    go mod edit -go "${GO}" && \
    go get -u && \
    go mod tidy && \
    go install -v -ldflags "-X main.AppVersion='${GUCCI_VER}' -w -extldflags static" && \
    install -m 0755 -o root -g root /go/bin/gucci /gucci

ARG GOTEMPLATE_SRC

FROM "ubuntu:24.04" AS base

ENV TGT="/tgt"
RUN --mount=type=bind,target=/src \
    --mount=type=bind,from=gucci,target=/gucci \
    mkdir -p "${TGT}/usr/local/bin" && \
    ( tar --owner=root --group=root --mode=u=rwX,go=rX -cf - /src/scripts ) | tar --strip-components=2 -C "${TGT}/usr/local/bin" -xvf - && \
    install -m 0755 -o root -g root /src/functions "${TGT}/.functions" && \
    install -m 0755 -o root -g root /src/entrypoint "${TGT}" && \
    install -m 0755 -o root -g root /gucci/gucci "${TGT}/usr/local/bin"

# Use this instead of Gucci when the time is right. It's better maintained
# and has many more features
# ADD --chown=root:root --chmod=0755 "${GOTEMPLATE_SRC}" "/usr/local/bin/gotemplate"

FROM scratch

ARG TGT

COPY --from=base /tgt/ /
