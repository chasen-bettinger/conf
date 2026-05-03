#!/usr/bin/env bats

load 'helpers/setup.bash'

setup() {
    common_setup
    # Blank out all checksums in the fixture registry so we can observe writes
    yq -i '.gitleaks.checksums |= with_entries(.value = "")' "$GH_INSTALL_REGISTRY"
    yq -i '.bw.checksums       |= with_entries(.value = "")' "$GH_INSTALL_REGISTRY"
}
teardown() { common_teardown; }

# 4.13a Per-asset .sha256 path
@test "get_checksums: parses per-asset *.sha256 and writes hashes" {
    # Force aggregate-file fallback to fail so only sidecars succeed
    export MOCK_CURL_DENY=$'SHA256SUMS\nchecksums.txt'

    run "${REPO_DIR}/get_checksums"
    [ "$status" -eq 0 ]

    # All 4 gitleaks platforms got hashes
    [ "$(yq '.gitleaks.checksums."linux-amd64"'  "$GH_INSTALL_REGISTRY")" = "8799a66d5a3292776ced60e068244d87cf38f8b6b8169de4400202ad4e006ac2" ]
    [ "$(yq '.gitleaks.checksums."linux-arm64"'  "$GH_INSTALL_REGISTRY")" = "8799a66d5a3292776ced60e068244d87cf38f8b6b8169de4400202ad4e006ac2" ]
    [ "$(yq '.gitleaks.checksums."darwin-amd64"' "$GH_INSTALL_REGISTRY")" = "8799a66d5a3292776ced60e068244d87cf38f8b6b8169de4400202ad4e006ac2" ]
    [ "$(yq '.gitleaks.checksums."darwin-arm64"' "$GH_INSTALL_REGISTRY")" = "8799a66d5a3292776ced60e068244d87cf38f8b6b8169de4400202ad4e006ac2" ]

    # All 4 bw platforms got hashes
    [ "$(yq '.bw.checksums."darwin-arm64"' "$GH_INSTALL_REGISTRY")" = "de866852cd0c94bdcb00e2142692a28ca81d0b2fbdc7b8f2d3287fb624e7541c" ]
}

# 4.13b SHA256SUMS aggregate path
@test "get_checksums: falls back to SHA256SUMS aggregate when no .sha256 sidecars" {
    export MOCK_CURL_DENY=$'.sha256\nchecksums.txt'

    run "${REPO_DIR}/get_checksums"
    [ "$status" -eq 0 ]

    [ "$(yq '.gitleaks.checksums."linux-amd64"'  "$GH_INSTALL_REGISTRY")" = "8799a66d5a3292776ced60e068244d87cf38f8b6b8169de4400202ad4e006ac2" ]
    [ "$(yq '.gitleaks.checksums."darwin-arm64"' "$GH_INSTALL_REGISTRY")" = "8799a66d5a3292776ced60e068244d87cf38f8b6b8169de4400202ad4e006ac2" ]
}

# 4.13c checksums.txt path
@test "get_checksums: falls back to checksums.txt when no .sha256 and no SHA256SUMS" {
    export MOCK_CURL_DENY=$'.sha256\nSHA256SUMS'

    run "${REPO_DIR}/get_checksums"
    [ "$status" -eq 0 ]

    [ "$(yq '.bw.checksums."linux-amd64"'  "$GH_INSTALL_REGISTRY")" = "de866852cd0c94bdcb00e2142692a28ca81d0b2fbdc7b8f2d3287fb624e7541c" ]
    [ "$(yq '.bw.checksums."darwin-arm64"' "$GH_INSTALL_REGISTRY")" = "de866852cd0c94bdcb00e2142692a28ca81d0b2fbdc7b8f2d3287fb624e7541c" ]
}

# 4.14 No published checksums file: warn, leave entry untouched, exit zero
@test "get_checksums: no checksums file available -> warn + skip + exit zero" {
    # Pre-populate gitleaks linux-amd64 with a known stale value to confirm it's preserved
    yq -i '.gitleaks.checksums."linux-amd64" = "STALE_VALUE_PRESERVED"' "$GH_INSTALL_REGISTRY"
    export MOCK_CURL_DENY=$'.sha256\nSHA256SUMS\nchecksums.txt'

    run "${REPO_DIR}/get_checksums"
    [ "$status" -eq 0 ]

    grep -q 'no checksums found' <<<"$output"
    [ "$(yq '.gitleaks.checksums."linux-amd64"' "$GH_INSTALL_REGISTRY")" = "STALE_VALUE_PRESERVED" ]
}

# 6.5.9 checksums_template short-circuits the default search
@test "get_checksums: checksums_template is set -> uses templated URL only, never SHA256SUMS/checksums.txt/.sha256" {
    yq -i '.gitleaks.checksums_template = "https://example.test/gitleaks/gitleaks/releases/download/v8.16.4/gitleaks_8.16.4_checksums.txt"' \
        "$GH_INSTALL_REGISTRY"
    # Strip bw to keep this test focused on gitleaks
    yq -i 'del(.bw)' "$GH_INSTALL_REGISTRY"

    run "${REPO_DIR}/get_checksums"
    [ "$status" -eq 0 ]

    # All four gitleaks platforms got the hash
    [ "$(yq '.gitleaks.checksums."linux-amd64"'  "$GH_INSTALL_REGISTRY")" = "8799a66d5a3292776ced60e068244d87cf38f8b6b8169de4400202ad4e006ac2" ]
    [ "$(yq '.gitleaks.checksums."linux-arm64"'  "$GH_INSTALL_REGISTRY")" = "8799a66d5a3292776ced60e068244d87cf38f8b6b8169de4400202ad4e006ac2" ]
    [ "$(yq '.gitleaks.checksums."darwin-amd64"' "$GH_INSTALL_REGISTRY")" = "8799a66d5a3292776ced60e068244d87cf38f8b6b8169de4400202ad4e006ac2" ]
    [ "$(yq '.gitleaks.checksums."darwin-arm64"' "$GH_INSTALL_REGISTRY")" = "8799a66d5a3292776ced60e068244d87cf38f8b6b8169de4400202ad4e006ac2" ]

    # The fallback URLs were never requested
    ! grep -q 'SHA256SUMS' "$MOCK_CURL_LOG"
    ! grep -q '/checksums\.txt$' "$MOCK_CURL_LOG"
    ! grep -q '\.sha256$' "$MOCK_CURL_LOG"
}

# 6.5.10 Empty asset_template_overrides value: silently skip platform
@test "get_checksums: empty asset_template_overrides value -> platform skipped silently" {
    yq -i '.gitleaks.asset_template_overrides."linux-arm64" = ""' "$GH_INSTALL_REGISTRY"
    yq -i 'del(.bw)' "$GH_INSTALL_REGISTRY"
    export MOCK_CURL_DENY=$'.sha256\nchecksums.txt'

    run "${REPO_DIR}/get_checksums"
    [ "$status" -eq 0 ]

    # No warning for the silently-skipped platform
    ! grep -q 'no checksum found for gitleaks/linux-arm64' <<<"$output"
    # And no curl request for that platform's URL
    ! grep -q 'gitleaks_8.16.4_linux_arm64.tar.gz' "$MOCK_CURL_LOG"
}

# 6.6.6 Local fallback: enabled + no hosted checksums -> all platforms computed locally
@test "get_checksums: local_checksums_fallback=true + no hosted checksums -> computes all platforms locally" {
    yq -i '.gitleaks.local_checksums_fallback = true' "$GH_INSTALL_REGISTRY"
    yq -i 'del(.bw)' "$GH_INSTALL_REGISTRY"
    export MOCK_CURL_DENY=$'.sha256\nSHA256SUMS\nchecksums.txt'

    expected_linux_x64=$(sha256sum    "${FIXTURES_DIR}/gitleaks_8.16.4_linux_x64.tar.gz"    | awk '{print $1}')
    expected_linux_arm64=$(sha256sum  "${FIXTURES_DIR}/gitleaks_8.16.4_linux_arm64.tar.gz"  | awk '{print $1}')
    expected_darwin_x64=$(sha256sum   "${FIXTURES_DIR}/gitleaks_8.16.4_darwin_x64.tar.gz"   | awk '{print $1}')
    expected_darwin_arm64=$(sha256sum "${FIXTURES_DIR}/gitleaks_8.16.4_darwin_arm64.tar.gz" | awk '{print $1}')

    run "${REPO_DIR}/get_checksums"
    [ "$status" -eq 0 ]

    [ "$(yq '.gitleaks.checksums."linux-amd64"'  "$GH_INSTALL_REGISTRY")" = "$expected_linux_x64" ]
    [ "$(yq '.gitleaks.checksums."linux-arm64"'  "$GH_INSTALL_REGISTRY")" = "$expected_linux_arm64" ]
    [ "$(yq '.gitleaks.checksums."darwin-amd64"' "$GH_INSTALL_REGISTRY")" = "$expected_darwin_x64" ]
    [ "$(yq '.gitleaks.checksums."darwin-arm64"' "$GH_INSTALL_REGISTRY")" = "$expected_darwin_arm64" ]

    grep -q 'computed locally gitleaks/linux-amd64'  <<<"$output"
    grep -q 'computed locally gitleaks/darwin-arm64' <<<"$output"
}

# 6.6.7 Local fallback: one platform's asset download fails -> that one warns, others fill
@test "get_checksums: local_checksums_fallback download failure for one platform -> warn + skip that slot" {
    yq -i '.gitleaks.local_checksums_fallback = true' "$GH_INSTALL_REGISTRY"
    yq -i 'del(.bw)' "$GH_INSTALL_REGISTRY"
    yq -i '.gitleaks.checksums."darwin-arm64" = "PRIOR_VALUE"' "$GH_INSTALL_REGISTRY"
    export MOCK_CURL_DENY=$'.sha256\nSHA256SUMS\nchecksums.txt\ngitleaks_8.16.4_darwin_arm64.tar.gz'

    expected_linux_x64=$(sha256sum   "${FIXTURES_DIR}/gitleaks_8.16.4_linux_x64.tar.gz"   | awk '{print $1}')
    expected_linux_arm64=$(sha256sum "${FIXTURES_DIR}/gitleaks_8.16.4_linux_arm64.tar.gz" | awk '{print $1}')
    expected_darwin_x64=$(sha256sum  "${FIXTURES_DIR}/gitleaks_8.16.4_darwin_x64.tar.gz"  | awk '{print $1}')

    run "${REPO_DIR}/get_checksums"
    [ "$status" -eq 0 ]

    [ "$(yq '.gitleaks.checksums."linux-amd64"'  "$GH_INSTALL_REGISTRY")" = "$expected_linux_x64" ]
    [ "$(yq '.gitleaks.checksums."linux-arm64"'  "$GH_INSTALL_REGISTRY")" = "$expected_linux_arm64" ]
    [ "$(yq '.gitleaks.checksums."darwin-amd64"' "$GH_INSTALL_REGISTRY")" = "$expected_darwin_x64" ]
    [ "$(yq '.gitleaks.checksums."darwin-arm64"' "$GH_INSTALL_REGISTRY")" = "PRIOR_VALUE" ]
    grep -q 'local hash fallback for gitleaks/darwin-arm64' <<<"$output"
}

# 6.6.8 Default (unset): no upstream and no fallback -> no asset downloads attempted
@test "get_checksums: local_checksums_fallback unset + no hosted checksums -> warn-and-skip, no asset download" {
    yq -i 'del(.bw)' "$GH_INSTALL_REGISTRY"
    yq -i '.gitleaks.checksums."linux-amd64" = "STALE_PRESERVED"' "$GH_INSTALL_REGISTRY"
    export MOCK_CURL_DENY=$'.sha256\nSHA256SUMS\nchecksums.txt'

    run "${REPO_DIR}/get_checksums"
    [ "$status" -eq 0 ]

    # Stale value preserved (script never tried to download the asset)
    [ "$(yq '.gitleaks.checksums."linux-amd64"' "$GH_INSTALL_REGISTRY")" = "STALE_PRESERVED" ]
    # The actual asset URL must NOT have been requested by the script
    ! grep -q 'gitleaks_8.16.4_linux_x64.tar.gz$' "$MOCK_CURL_LOG"
    grep -q 'no checksums found for gitleaks' <<<"$output"
}

# 4.15 One platform asset missing from aggregate file
@test "get_checksums: missing one platform asset -> warn for that one, others written, prior preserved" {
    # Redirect SHA256SUMS to the partial fixture (gitleaks darwin-arm64 missing)
    cat > "${TEST_TMP}/curl_map" <<EOF
https://example.test/gitleaks/gitleaks/releases/download/v8.16.4/SHA256SUMS partial_SHA256SUMS
https://example.test/bitwarden/clients/releases/download/cli-v2026.2.0/SHA256SUMS partial_SHA256SUMS
EOF
    export MOCK_CURL_MAP="${TEST_TMP}/curl_map"
    export MOCK_CURL_DENY=$'.sha256\nchecksums.txt'

    # Pre-populate gitleaks darwin-arm64 with a known prior value
    yq -i '.gitleaks.checksums."darwin-arm64" = "PRIOR_VALUE_KEPT"' "$GH_INSTALL_REGISTRY"

    run "${REPO_DIR}/get_checksums"
    [ "$status" -eq 0 ]

    [ "$(yq '.gitleaks.checksums."linux-amd64"'  "$GH_INSTALL_REGISTRY")" = "8799a66d5a3292776ced60e068244d87cf38f8b6b8169de4400202ad4e006ac2" ]
    [ "$(yq '.gitleaks.checksums."linux-arm64"'  "$GH_INSTALL_REGISTRY")" = "8799a66d5a3292776ced60e068244d87cf38f8b6b8169de4400202ad4e006ac2" ]
    [ "$(yq '.gitleaks.checksums."darwin-amd64"' "$GH_INSTALL_REGISTRY")" = "8799a66d5a3292776ced60e068244d87cf38f8b6b8169de4400202ad4e006ac2" ]
    # Missing platform: prior value preserved
    [ "$(yq '.gitleaks.checksums."darwin-arm64"' "$GH_INSTALL_REGISTRY")" = "PRIOR_VALUE_KEPT" ]
    grep -q 'no checksum found for gitleaks/darwin-arm64' <<<"$output"
}
