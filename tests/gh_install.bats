#!/usr/bin/env bats

load 'helpers/setup.bash'

setup() { common_setup; }
teardown() { common_teardown; }

# 4.5 Registry resolution: template substitution + os_map/arch_map overrides
@test "resolves linux/amd64 gitleaks URL with arch_map override (amd64 -> x64)" {
    run "${REPO_DIR}/gh_install" gitleaks "$INSTALL_DIR"
    [ "$status" -eq 0 ]
    grep -q 'gitleaks_8.16.4_linux_x64.tar.gz$' "$MOCK_CURL_LOG"
}

@test "resolves darwin/arm64 bw URL with os_map override (darwin -> macos)" {
    export MOCK_UNAME_S="Darwin" MOCK_UNAME_M="arm64"
    run "${REPO_DIR}/gh_install" bw "$INSTALL_DIR"
    [ "$status" -eq 0 ]
    grep -q 'bw-macos-arm64-2026.2.0.zip$' "$MOCK_CURL_LOG"
}

# 4.6 OS/arch normalization
@test "Linux/x86_64 normalizes to linux/amd64" {
    export MOCK_UNAME_S="Linux" MOCK_UNAME_M="x86_64"
    run "${REPO_DIR}/gh_install" gitleaks "$INSTALL_DIR"
    [ "$status" -eq 0 ]
    grep -q 'linux_x64' "$MOCK_CURL_LOG"
}

@test "Linux/aarch64 normalizes to linux/arm64 (URL resolution only)" {
    export MOCK_UNAME_S="Linux" MOCK_UNAME_M="aarch64"
    # No checksum populated for linux-arm64 → script exits before download.
    # URL resolution still has to happen for the checksum lookup to find the slot empty.
    run "${REPO_DIR}/gh_install" gitleaks "$INSTALL_DIR"
    [ "$status" -ne 0 ]
    grep -q 'no checksum recorded for gitleaks/linux-arm64' <<<"$output"
}

@test "Darwin/x86_64 normalizes to darwin/amd64" {
    export MOCK_UNAME_S="Darwin" MOCK_UNAME_M="x86_64"
    run "${REPO_DIR}/gh_install" gitleaks "$INSTALL_DIR"
    [ "$status" -ne 0 ]
    grep -q 'darwin-amd64' <<<"$output"
}

@test "Darwin/arm64 normalizes to darwin/arm64" {
    export MOCK_UNAME_S="Darwin" MOCK_UNAME_M="arm64"
    run "${REPO_DIR}/gh_install" gitleaks "$INSTALL_DIR"
    [ "$status" -eq 0 ]
    grep -q 'darwin_arm64' "$MOCK_CURL_LOG"
}

@test "Linux/armv7l exits non-zero with arch error" {
    export MOCK_UNAME_S="Linux" MOCK_UNAME_M="armv7l"
    run "${REPO_DIR}/gh_install" gitleaks "$INSTALL_DIR"
    [ "$status" -ne 0 ]
    grep -q 'unsupported architecture' <<<"$output"
}

# 4.7 Checksum match → install succeeds, binary at INSTALL_DIR, state file has version
@test "checksum match: installs binary and writes state file" {
    run "${REPO_DIR}/gh_install" gitleaks "$INSTALL_DIR"
    [ "$status" -eq 0 ]
    [ -x "${INSTALL_DIR}/gitleaks" ]
    state="$(state_file)"
    [ -f "$state" ]
    grep -q 'gitleaks: 8.16.4' "$state"
}

# 4.8 Checksum mismatch → exit non-zero, install dir unchanged, temp gone, state unchanged
@test "checksum mismatch: exits non-zero, leaves nothing installed, no state" {
    # Corrupt the registry checksum
    BINARY_KEY=gitleaks PLATFORM=linux-amd64 yq -i \
        '.[strenv(BINARY_KEY)].checksums[strenv(PLATFORM)] = "0000000000000000000000000000000000000000000000000000000000000000"' \
        "$GH_INSTALL_REGISTRY"

    run "${REPO_DIR}/gh_install" gitleaks "$INSTALL_DIR"
    [ "$status" -ne 0 ]
    grep -q 'checksum mismatch' <<<"$output"
    [ ! -e "${INSTALL_DIR}/gitleaks" ]
    [ ! -f "$(state_file)" ]
}

# 4.9 Missing checksum → exit non-zero with "run get_checksums" hint
@test "missing checksum: exits non-zero with run-get_checksums hint" {
    BINARY_KEY=gitleaks PLATFORM=linux-amd64 yq -i \
        '.[strenv(BINARY_KEY)].checksums[strenv(PLATFORM)] = ""' "$GH_INSTALL_REGISTRY"
    run "${REPO_DIR}/gh_install" gitleaks "$INSTALL_DIR"
    [ "$status" -ne 0 ]
    grep -q 'no checksum recorded' <<<"$output"
    grep -q 'get_checksums' <<<"$output"
    [ ! -e "${INSTALL_DIR}/gitleaks" ]
}

# 4.10 Idempotency
@test "idempotency: skip when state file matches registry version" {
    # First install
    run "${REPO_DIR}/gh_install" gitleaks "$INSTALL_DIR"
    [ "$status" -eq 0 ]
    rm -f "$MOCK_CURL_LOG"

    # Second invocation should skip download
    run "${REPO_DIR}/gh_install" gitleaks "$INSTALL_DIR"
    [ "$status" -eq 0 ]
    grep -q 'already installed' <<<"$output"
    [ ! -s "$MOCK_CURL_LOG" ]
}

@test "idempotency: reinstall when state version differs from registry" {
    state="$(state_file)"
    mkdir -p "$(dirname "$state")"
    echo "gitleaks: 8.0.0" > "$state"

    run "${REPO_DIR}/gh_install" gitleaks "$INSTALL_DIR"
    [ "$status" -eq 0 ]
    [ -x "${INSTALL_DIR}/gitleaks" ]
    grep -q 'gitleaks: 8.16.4' "$state"
}

@test "idempotency: first install creates state file under HOME/.local/state" {
    [ ! -f "$(state_file)" ]
    run "${REPO_DIR}/gh_install" gitleaks "$INSTALL_DIR"
    [ "$status" -eq 0 ]
    state="$(state_file)"
    [ -f "$state" ]
    grep -q 'gitleaks: 8.16.4' "$state"
}

@test "idempotency: removing state entry triggers reinstall" {
    run "${REPO_DIR}/gh_install" gitleaks "$INSTALL_DIR"
    [ "$status" -eq 0 ]
    state="$(state_file)"
    yq -i 'del(.gitleaks)' "$state"
    rm -f "$MOCK_CURL_LOG"
    rm -f "${INSTALL_DIR}/gitleaks"

    run "${REPO_DIR}/gh_install" gitleaks "$INSTALL_DIR"
    [ "$status" -eq 0 ]
    [ -x "${INSTALL_DIR}/gitleaks" ]
    [ -s "$MOCK_CURL_LOG" ]
    grep -q 'gitleaks: 8.16.4' "$state"
}

# 4.11 Unknown binary key
@test "unknown binary key: exits non-zero, lists available keys" {
    run "${REPO_DIR}/gh_install" nonexistent "$INSTALL_DIR"
    [ "$status" -ne 0 ]
    grep -q 'is not in the registry' <<<"$output"
    grep -q 'gitleaks' <<<"$output"
    grep -q 'bw' <<<"$output"
}

# 4.12 Extraction failure leaves no files behind
@test "extraction failure: corrupt archive leaves nothing installed" {
    # Point the registry at the corrupt fixture by templating.
    BINARY_KEY=gitleaks yq -i \
        '.[strenv(BINARY_KEY)].asset_template = "https://example.test/{source}/v{version}/corrupt_{version}_{os}_{arch}.tar.gz"' \
        "$GH_INSTALL_REGISTRY"
    BINARY_KEY=gitleaks PLATFORM=linux-amd64 yq -i \
        '.[strenv(BINARY_KEY)].checksums[strenv(PLATFORM)] = "9844e7b2a73823943e52ee995c57b3b0291cb3cfbaabae94e5ca58686f54bcae"' \
        "$GH_INSTALL_REGISTRY"

    run "${REPO_DIR}/gh_install" gitleaks "$INSTALL_DIR"
    [ "$status" -ne 0 ]
    [ ! -e "${INSTALL_DIR}/gitleaks" ]
    [ ! -f "$(state_file)" ]
}

# 6.5.7 Empty asset_template_overrides value: platform unsupported
@test "asset_template_overrides empty value: gh_install refuses with does-not-support message" {
    BINARY_KEY=gitleaks PLATFORM=linux-amd64 yq -i \
        '.[strenv(BINARY_KEY)].asset_template_overrides[strenv(PLATFORM)] = ""' "$GH_INSTALL_REGISTRY"

    run "${REPO_DIR}/gh_install" gitleaks "$INSTALL_DIR"
    [ "$status" -ne 0 ]
    grep -q 'does not support linux-amd64' <<<"$output"
    [ ! -e "${INSTALL_DIR}/gitleaks" ]
    [ ! -f "$(state_file)" ]
    [ ! -s "$MOCK_CURL_LOG" ]
}

# 6.5.8 Non-empty asset_template_overrides value: override template wins
@test "asset_template_overrides non-empty: override template is used (verified via curl log)" {
    BINARY_KEY=gitleaks PLATFORM=linux-amd64 yq -i \
        '.[strenv(BINARY_KEY)].asset_template_overrides[strenv(PLATFORM)] = "https://example.test/override/gitleaks_8.16.4_linux_x64.tar.gz"' \
        "$GH_INSTALL_REGISTRY"

    run "${REPO_DIR}/gh_install" gitleaks "$INSTALL_DIR"
    [ "$status" -eq 0 ]
    grep -q '^https://example.test/override/gitleaks_8.16.4_linux_x64.tar.gz$' "$MOCK_CURL_LOG"
    # And the default (.../releases/download/...) URL was NOT requested
    ! grep -q 'releases/download' "$MOCK_CURL_LOG"
}

# Bonus: zero-arg usage
@test "zero arguments: prints usage and exits non-zero" {
    run "${REPO_DIR}/gh_install"
    [ "$status" -ne 0 ]
    grep -q 'Usage:' <<<"$output"
}
