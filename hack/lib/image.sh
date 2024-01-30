#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Image variables helpers. These functions need the
# following variables:
#
#    MANIFEST_TOOL_VERSION  -  The Manifest Tool version for running, default is 2.0.3.
#          DOCKER_VERSION   -  The Docker version for running, default is 20.10.
#         DOCKER_USERNAME   -  The username of image registry.
#         DOCKER_PASSWORD   -  The password of image registry.

docker_version=${DOCKER_VERSION:-"20.10"}
manifest_tool_version=${MANIFEST_TOOL_VERSION:-"2.0.3"}
docker_username=${DOCKER_USERNAME:-}
docker_password=${DOCKER_PASSWORD:-}

function seal::image::docker::install() {
  curl --retry 3 --retry-all-errors --retry-delay 3 \
    -sSfL "https://get.docker.com" | sh -s VERSION="${docker_version}"
}

function seal::image::docker::validate() {
  # shellcheck disable=SC2046
  if [[ -n "$(command -v $(seal::image::docker::bin))" ]]; then
    return 0
  fi

  seal::log::info "installing docker"
  if seal::image::docker::install; then
    seal::log::info "docker: $($(seal::image::docker::bin) version --format '{{.Server.Version}}' 2>&1)"
    return 0
  fi
  seal::log::error "no docker available"
  return 1
}

function seal::image::docker::bin() {
  echo -n "docker"
}

function seal::image::manifest_tool::install() {
  curl --retry 3 --retry-all-errors --retry-delay 3 -sSfL "https://github.com/estesp/manifest-tool/releases/download/v${manifest_tool_version}/binaries-manifest-tool-${manifest_tool_version}.tar.gz" -o /tmp/manifest-clientset.tar.gz
  tar -xzf /tmp/manifest-clientset.tar.gz -C /tmp
  # shellcheck disable=SC2155
  local bin="manifest-tool-$(seal::util::get_os)-$(seal::util::get_arch ---full-name)"
  chmod +x "/tmp/${bin}" && mv "/tmp/${bin}" "${ROOT_SBIN_DIR}/manifest-tool"
}

function seal::image::manifest_tool::validate() {
  # shellcheck disable=SC2046
  if [[ -n "$(command -v $(seal::image::manifest_tool::bin))" ]]; then
    if [[ $($(seal::image::manifest_tool::bin) --version 2>&1 | cut -d " " -f 3 2>&1) == "${manifest_tool_version}" ]]; then
      return 0
    fi
  fi

  seal::log::info "installing manifest-tool ${manifest_tool_version}"
  if seal::image::manifest_tool::install; then
    seal::log::info "manifest_tool $($(seal::image::manifest_tool::bin) --version 2>&1 | cut -d " " -f 3 2>&1)"
    return 0
  fi
  seal::log::error "no manifest-tool available"
  return 1
}

function seal::image::manifest_tool::bin() {
  local bin="manifest-tool"
  if [[ -f "${ROOT_SBIN_DIR}/manifest-tool" ]]; then
    bin="${ROOT_SBIN_DIR}/manifest-tool"
  fi
  echo -n "${bin}"
}

function seal::image::name() {
  if [[ -n "${IMAGE:-}" ]]; then
    echo -n "${IMAGE}"
  else
    echo -n "$(basename "${ROOT_DIR}")" 2>/dev/null
  fi
}

function seal::image::tag() {
  echo -n "${TAG:-${GIT_VERSION}}" | sed -E 's/[^a-zA-Z0-9\.]+/-/g' 2>/dev/null
}

function seal::image::build() {
  if seal::image::docker::validate; then
    seal::log::debug "docker build $*"
    DOCKER_CLI_EXPERIMENTAL=enabled DOCKER_BUILDKIT=1 \
      $(seal::image::docker::bin) build "$@"
    return 0
  fi

  seal::log::fatal "cannot execute image build as client is not found"
}

function seal::image::run() {
  if seal::image::docker::validate; then
    seal::log::debug "docker run $*"
    DOCKER_CLI_EXPERIMENTAL=enabled DOCKER_BUILDKIT=1 \
      $(seal::image::docker::bin) run "$@"
    return 0
  fi

  seal::log::fatal "cannot run image as client is not found"
}

function seal::image::rmi() {
  if seal::image::docker::validate; then
    seal::log::debug "docker rmi $*"
    DOCKER_CLI_EXPERIMENTAL=enabled DOCKER_BUILDKIT=1 \
      $(seal::image::docker::bin) rmi "$@"
    return 0
  fi

  seal::log::fatal "cannot execute image deletion as client is not found"
}

function seal::image::login() {
  if seal::image::docker::validate; then
    if [[ -n ${docker_username} ]] && [[ -n ${docker_password} ]]; then
      seal::log::debug "docker login ${*:-} -u ${docker_username} -p ***"
      if ! docker login "${*:-}" -u "${docker_username}" -p "${docker_password}" >/dev/null 2>&1; then
        seal::log::fatal "failed: docker login ${*:-} -u ${docker_username} -p ***"
      fi
    fi
    return 0
  fi

  seal::log::fatal "cannot execute image login as client is not found"
}

function seal::image::push() {
  if seal::image::docker::validate; then
    if $(seal::image::docker::bin) image inspect "$1" >/dev/null 2>&1; then
      seal::log::debug "docker push $1"
      for i in $(seq 1 5); do
        if $(seal::image::docker::bin) push "$1"; then
          break
        fi
      done
      if [[ $i -ge 5 ]]; then
        seal::log::fatal "failed: docker push $1"
      fi
    else
      seal::log::warn "image $1 is not found in local"
    fi
    return 0
  fi

  seal::log::fatal "cannot execute image push as client is not found"
}

function seal::image::manifest() {
  if seal::image::manifest_tool::validate; then
    if [[ $(seal::util::get_os) == "darwin" ]]; then
      if [[ -z ${docker_username} ]] && [[ -z ${docker_password} ]]; then
        # NB(thxCode): since 17.03, Docker for Mac stores credentials in the OSX/maseal keychain and not in resource.json,
        # which means the above variables need to specify if using on Mac.
        seal::log::fatal "must set 'DOCKER_USERNAME' & 'DOCKER_PASSWORD' environment variables in Darwin platform"
      fi
    fi
    if [[ -n ${docker_username} ]] && [[ -n ${docker_password} ]]; then
      seal::log::debug "manifest-tool --username=${docker_username} --password=*** push from-args --ignore-missing $*"
      for i in $(seq 1 5); do
        if $(seal::image::manifest_tool::bin) --username="${docker_username}" --password="${docker_password}" push from-args --ignore-missing "$@"; then
          break
        fi
      done
      if [[ $i -ge 5 ]]; then
        seal::log::fatal "failed: manifest-tool --username=${docker_username} --password=*** push from-args --ignore-missing $*"
      fi
    else
      seal::log::debug "manifest-tool push from-args $*"
      for i in $(seq 1 5); do
        if $(seal::image::manifest_tool::bin) push from-args --ignore-missing "$@"; then
          break
        fi
      done
      if [[ $i -ge 5 ]]; then
        seal::log::fatal "failed: manifest-tool push from-args --ignore-missing $*"
      fi
    fi
    return 0
  fi

  seal::log::fatal "cannot execute image manifest as client is not found"
}
