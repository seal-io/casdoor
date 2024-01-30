#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
pushd "${ROOT_DIR}" >/dev/null 2>&1

make lint
make build
make test
make package

popd >/dev/null 2>&1
