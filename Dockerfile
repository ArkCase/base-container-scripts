ARG FIPS=""
ARG PRIVATE_REGISTRY
ARG VER="1.0.0"
ARG OS="linux"
ARG GOOS="linux"
ARG GOARCH="amd64"
ARG PKG="base-scripts"

ARG GO="1.26"
ARG BUILDER_IMAGE="golang"
ARG BUILDER_VER="${GO}-alpine"
ARG BUILDER_IMG="${BUILDER_IMAGE}:${BUILDER_VER}"

ARG GOTEMPLATE_VER="5.2.0"
ARG GOTEMPLATE_SRC="https://github.com/hairyhenderson/gomplate/releases/download/v${GOTEMPLATE_VER}/gomplate_${GOOS}-${GOARCH}"

FROM "${BUILDER_IMG}" AS gucci

ARG GO
ARG GUCCI_REPO="https://github.com/noqcks/gucci.git"
ARG GUCCI_VER="1.9.0"

RUN apk --no-cache add git

ENV SRCPATH="/build/gucci"
ENV GO111MODULE="on"
ENV CGO_ENABLED="0"
RUN mkdir -p "${SRCPATH}" && \
    cd "${SRCPATH}" && \
    git clone "${GUCCI_REPO}" "." --branch="v${GUCCI_VER}" && \
    go mod edit -go "${GO}" && \
    go get -u && \
    go mod tidy && \
    go install -v -ldflags "-X main.AppVersion='${GUCCI_VER}' -w -extldflags static" && \
    cp -vf /go/bin/gucci /gucci

FROM scratch

ARG GOTEMPLATE_SRC

COPY --chown=root:root --chmod=0755 functions /.functions
COPY --chown=root:root --chmod=0755 entrypoint /
COPY --chown=root:root --chmod=0755 scripts/ /usr/local/bin/
COPY --chown=root:root --chmod=0755 --from=gucci "/gucci" "/usr/local/bin/gucci"

# Use this instead of Gucci when the time is right. It's better maintained
# and has many more features
# ADD --chown=root:root --chmod=0755 "${GOTEMPLATE_SRC}" "/usr/local/bin/gotemplate"
