ARG FIPS=""
ARG PRIVATE_REGISTRY
ARG VER="1.0.0"
ARG OS="linux"
ARG PKG="base-scripts"

ARG GO="1.26"
ARG BUILDER_IMAGE="golang"
ARG BUILDER_VER="${GO}-alpine"
ARG BUILDER_IMG="${BUILDER_IMAGE}:${BUILDER_VER}"

FROM "${BUILDER_IMG}" AS gucci

ARG GO
ARG GUCCI_REPO="https://github.com/noqcks/gucci.git"
ARG GUCCI_VER="1.9.0"

RUN apk --no-cache add git

ENV SRCPATH="/build/gucci"
ENV GO111MODULE="on"
ENV CGO_ENABLED="0"
ENV GOOS="linux"
ENV GOARCH="amd64"
RUN mkdir -p "${SRCPATH}" && \
    cd "${SRCPATH}" && \
    git clone "${GUCCI_REPO}" "." --branch="v${GUCCI_VER}" && \
    go mod edit -go "${GO}" && \
    go get -u && \
    go mod tidy && \
    go install -v -ldflags "-X main.AppVersion='${GUCCI_VER}' -w -extldflags static" && \
    cp -vf /go/bin/gucci /gucci

FROM scratch

COPY --chown=root:root --chmod=0755 functions /.functions
COPY --chown=root:root --chmod=0755 entrypoint /
COPY --chown=root:root --chmod=0755 scripts/ /usr/local/bin/
COPY --chown=root:root --chmod=0755 --from=gucci "/gucci" "/usr/local/bin/gucci"
