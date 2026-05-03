#!/usr/bin/env bats

setup() {
    REPO_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"
    REGISTRY="${REPO_DIR}/binaries.yaml"
}

@test "registry parses with yq" {
    yq '.' "$REGISTRY" >/dev/null
}

@test "every entry has source, version, binary, asset_template, checksums" {
    while IFS= read -r key; do
        [[ -z "$key" ]] && continue
        for field in source version binary asset_template checksums; do
            BINARY_KEY="$key" FIELD="$field" run yq -e '.[strenv(BINARY_KEY)][strenv(FIELD)]' "$REGISTRY"
            [ "$status" -eq 0 ] || { echo "missing field $field on $key"; return 1; }
        done
    done < <(yq 'keys | .[]' "$REGISTRY")
}

@test "every entry has all four <os>-<arch> checksum keys" {
    expected="darwin-amd64 darwin-arm64 linux-amd64 linux-arm64"
    while IFS= read -r key; do
        [[ -z "$key" ]] && continue
        actual=$(BINARY_KEY="$key" yq '.[strenv(BINARY_KEY)].checksums | keys | sort | join(" ")' "$REGISTRY")
        [ "$actual" = "$expected" ] || { echo "$key has keys: $actual (expected: $expected)"; return 1; }
    done < <(yq 'keys | .[]' "$REGISTRY")
}

@test "every checksum value is empty or 64-char lowercase hex" {
    while IFS= read -r key; do
        [[ -z "$key" ]] && continue
        for plat in linux-amd64 linux-arm64 darwin-amd64 darwin-arm64; do
            value=$(BINARY_KEY="$key" PLATFORM="$plat" yq \
                '.[strenv(BINARY_KEY)].checksums[strenv(PLATFORM)] // ""' "$REGISTRY")
            if [[ -n "$value" && "$value" != "null" ]]; then
                [[ "$value" =~ ^[a-f0-9]{64}$ ]] || { echo "bad checksum at $key/$plat: $value"; return 1; }
            fi
        done
    done < <(yq 'keys | .[]' "$REGISTRY")
}
