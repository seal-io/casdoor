#!/usr/bin/env bash

readonly SUPPORTED_BUILD_PLATFORMS=(
  darwin/amd64
  darwin/arm64
  linux/amd64
  linux/arm64
)

function seal::target::build_platforms() {
  local platforms
  if [[ -z "${OS:-}" ]] && [[ -z "${ARCH:-}" ]]; then
    if [[ -n "${BUILD_PLATFORMS:-}" ]]; then
      IFS="," read -r -a platforms <<<"${BUILD_PLATFORMS}"
    else
      platforms=("${SUPPORTED_BUILD_PLATFORMS[@]}")
    fi
  else
    local os="${OS:-$(seal::util::get_os)}"
    local arch="${ARCH:-$(seal::util::get_arch)}"
    platforms=("${os}/${arch}")
  fi
  echo -n "${platforms[@]}"
}
