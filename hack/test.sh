#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source "${ROOT_DIR}/hack/lib/init.sh"

mkdir -p "${ROOT_DIR}/dist"

function test() {
  go test \
    -v \
    -short \
    -failfast \
    -timeout=5m \
    -cover \
    -coverprofile="${ROOT_DIR}/dist/coverage.out" ./...
}

#
# main
#

if [[ "${TEST_DELEGATE:-false}" == "false" ]]; then
  seal::log::info "+++ TEST +++"

  test

  seal::log::info "--- TEST ---"
fi
