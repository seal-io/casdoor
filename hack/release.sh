#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source "${ROOT_DIR}/hack/lib/init.sh"

function before_release() {
  seal::image::login
}

function release() {
  local repo=${REPO:-sealio}
  # shellcheck disable=SC2155
  local image="$(seal::image::name)"
  # shellcheck disable=SC2155
  local tag="$(seal::image::tag)"

  local image_tag="${repo}/${image}:${tag}"

  local release_platforms=()
  # shellcheck disable=SC2207
  local platforms=()
  IFS=" " read -r -a platforms <<<"$(seal::target::build_platforms)"
  for platform in "${platforms[@]}"; do
    local specified_image_tag="${image_tag}-${platform////-}"
    if [[ "${platform}" =~ darwin/* ]] || [[ "${platform}" =~ windows/* ]]; then
      seal::log::warn "buildx releasing ${image_tag} is not supported now"
      continue
    fi
    release_platforms+=("${platform}")
    seal::log::info "pushing ${specified_image_tag}"
    seal::image::push "${specified_image_tag}"
  done

  seal::log::info "releasing ${image_tag}"
  # shellcheck disable=SC2046
  seal::image::manifest \
    --platforms=$(seal::util::join_array "," "${release_platforms[@]}") \
    --template="${image_tag}-OS-ARCH" \
    --target="${image_tag}"
}

#
# main
#

if [[ "${RELEASE_DELEGATE:-false}" == "false" ]]; then
  seal::log::info "+++ RELEASE +++" "tag: $(seal::image::tag)"

  before_release
  release

  seal::log::info "--- RELEASE ---"
fi
