#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source "${ROOT_DIR}/hack/lib/init.sh"

mkdir -p "${ROOT_DIR}/bin"

function build() {
  local build_os
  build_os="$(seal::util::get_raw_os)"

  local platforms=()
  IFS=" " read -r -a platforms <<<"$(seal::target::build_platforms)"

  for platform in "${platforms[@]}"; do
    local os_arch
    IFS="/" read -r -a os_arch <<<"${platform}"
    local target_os="${os_arch[0]}"
    local target_arch="${os_arch[1]}"

    seal::log::info "building ${platform} on ${build_os}"
    case "${target_os}" in
    linux)
      GOOS="linux" GOARCH="${target_arch}" CGO_ENABLED=0 go build \
        -trimpath \
        -ldflags="-w -s -extldflags '-static'" \
        -o="${ROOT_DIR}/bin/casdoor-linux-${target_arch}" \
        "${ROOT_DIR}" &
      ;;
    windows)
      GOOS="windows" GOARCH="${target_arch}" CGO_ENABLED=0 go build \
        -trimpath \
        -ldflags="-w -s -extldflags '-static'" \
        -o="${ROOT_DIR}/bin/casdoor-windows-${target_arch}.exe" \
        "${ROOT_DIR}" &
      ;;
    darwin)
      GOOS="darwin" GOARCH="${target_arch}" CGO_ENABLED=0 go build \
        -trimpath \
        -ldflags="-w -s -extldflags '-static'" \
        -o="${ROOT_DIR}/bin/casdoor-darwin-${target_arch}" \
        "${ROOT_DIR}" &
      ;;
    esac
  done
  seal::util::wait_jobs || seal::log::fatal "failed to build"
}

#
# main
#

seal::log::info "+++ BUILD +++" "info: ${GIT_VERSION},${GIT_COMMIT:0:7},${GIT_TREE_STATE},${BUILD_DATE}"

build

seal::log::info "--- BUILD ---"
