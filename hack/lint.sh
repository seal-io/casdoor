#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source "${ROOT_DIR}/hack/lib/init.sh"

function lint() {
  if [[ "${LINT_DIRTY_CHECK:-false}" == "true" ]] && [[ -n "$(command -v git)" ]]; then
    if git_status=$(git status --porcelain 2>/dev/null) && [[ -n ${git_status} ]]; then
      seal::log::fatal "the git tree is dirty:\n${git_status}"
    fi
  fi

  seal::log::info "linting"
  touch /tmp/dummy.yml
  seal::lint::run --disable-all -c /tmp/dummy.yml -E=gofumpt --max-same-issues=0 --timeout 5m --modules-download-mode=mod "./..."
}

#
# main
#

if [[ "${LINT_DELEGATE:-false}" == "false" ]]; then
  seal::log::info "+++ LINT +++"

  lint

  seal::log::info "--- LINT ---"
fi
