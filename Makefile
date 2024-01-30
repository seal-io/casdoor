SHELL := /bin/bash

# Borrowed from https://stackoverflow.com/questions/18136918/how-to-get-current-relative-directory-of-your-makefile
curr_dir := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

# Borrowed from https://stackoverflow.com/questions/2214575/passing-arguments-to-make-run
rest_args := $(wordlist 2, $(words $(MAKECMDGOALS)), $(MAKECMDGOALS))
$(eval $(rest_args):;@:)

targets := $(shell ls $(curr_dir)/hack | sed 's/.sh//g')
$(targets):
	@$(curr_dir)/hack/$@.sh $(rest_args)

help:
	#
	# Usage:
	#
	#   * `make deps`, execute `go mod` commands.
	#
	#
	#   * `make lint`, leverage golangci-lint to verify the code tree,
	#     configuration is placing in `.golangci.yaml`.
	#     - `LINT_DIRTY_CHECK=true make lint` verify whether the code tree is dirty on CI.
	#     - `LINT_DELEGATE=true make lint` disable the default lint operating on CI.
	#
	#
	#   * `make build [target]`, parallel build all targets or the specified one.
	#     - `OS=darwin ARCH=amd64 make build` build all targets run on darwin/amd64 arch.
	#
	#
	#   * `make test`, execute unit tests.
	#     - `TEST_DELEGATE=true make test` disable the unit testing operation on CI.
	#
	#
	#   * `make package [target]`, parallel package all targets or the specified one.
	#     - `REPO=xyz make package` package all targets named with xyz repository.
	#     - `TAG=vX.y.z make package` package all targets named with vX.y.z tag.
	#     - `OS=linux ARCH=arm64 make package` package all targets run on linux/arm64 arch.
	#       with current tag on CI.
	#     - `PACKAGE_DELEGATE=true make lint` disable the default package operating on CI.
	#
	#
	#   * `make release [target]`, parallel upload the images produced by `make package`,
	#     must specify credential via `DOCKER_USERNAME=... DOCKER_PASSWORD=...`.
	#     - `REPO=xyz make release` upload all targets named with xyz repository.
	#     - `TAG=vX.y.z make release` upload all targets named with vX.y.z tag.
	#     - `OS=linux ARCH=arm64 make release` upload all targets run on linux/arm64 arch.
	#
	@echo
