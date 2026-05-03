#!/usr/bin/env bash
# Common bats setup/teardown for gh_install tests.
# Sources are expected from inside a bats file via:
#   load 'helpers/setup.bash'

common_setup() {
    REPO_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"
    FIXTURES_DIR="${REPO_DIR}/tests/fixtures"

    TEST_TMP="$(mktemp -d)"
    export TEST_TMP

    export HOME="${TEST_TMP}/home"
    mkdir -p "${HOME}"

    INSTALL_DIR="${TEST_TMP}/bin"
    mkdir -p "${INSTALL_DIR}"
    export INSTALL_DIR

    MOCK_BIN="${TEST_TMP}/mockbin"
    mkdir -p "${MOCK_BIN}"
    install -m 0755 "${REPO_DIR}/tests/helpers/mock_curl.bash"  "${MOCK_BIN}/curl"
    install -m 0755 "${REPO_DIR}/tests/helpers/mock_uname.bash" "${MOCK_BIN}/uname"

    PATH="${MOCK_BIN}:${PATH}"
    export PATH

    # Use the fixture registry and a writable copy
    cp "${FIXTURES_DIR}/binaries.yaml" "${TEST_TMP}/binaries.yaml"
    export GH_INSTALL_REGISTRY="${TEST_TMP}/binaries.yaml"
    export FIXTURES_DIR

    export MOCK_CURL_LOG="${TEST_TMP}/curl.log"

    # Default to linux/amd64 host
    export MOCK_UNAME_S="Linux"
    export MOCK_UNAME_M="x86_64"

    # Hermetic: forbid network for any tool that ignored our PATH shim
    unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
}

common_teardown() {
    if [[ -n "${TEST_TMP:-}" && -d "$TEST_TMP" ]]; then
        rm -rf "$TEST_TMP"
    fi
}

state_file() {
    echo "${HOME}/.local/state/gh_install/installed.yaml"
}
