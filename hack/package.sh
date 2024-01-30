#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source "${ROOT_DIR}/hack/lib/init.sh"

mkdir -p "${ROOT_DIR}/dist"

function package() {
  local repo=${REPO:-sealio}
  # shellcheck disable=SC2155
  local image="$(seal::image::name)"
  # shellcheck disable=SC2155
  local tag="$(seal::image::tag)"

  # shellcheck disable=SC2207
  local platforms=()
  IFS=" " read -r -a platforms <<<"$(seal::target::build_platforms)"

  for platform in "${platforms[@]}"; do
    local image_tag="${repo}/${image}:${tag}-${platform////-}"
    if [[ "${platform}" =~ darwin/* ]] || [[ "${platform}" =~ windows/* ]]; then
      seal::log::warn "buildx packaging ${image_tag} is not supported now"
      continue
    fi

    seal::log::info "packaging ${image_tag}"
    seal::image::build \
      --platform="${platform}" \
      --tag="${image_tag}" \
      --progress="plain" \
      --file="${ROOT_DIR}/hack/docker/Dockerfile" \
      "${ROOT_DIR}" &
  done
  seal::util::wait_jobs || seal::log::fatal "failed to package"
}

#
# main
#

if [[ "${PACKAGE_DELEGATE:-false}" == "false" ]]; then
  seal::log::info "+++ PACKAGE +++" "tag: $(seal::image::tag)"

  package

  seal::log::info "--- PACKAGE ---"
fi
