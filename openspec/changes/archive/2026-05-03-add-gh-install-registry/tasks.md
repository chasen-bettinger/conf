## 1. Registry

- [x] 1.1 Create `binaries.yaml` at the repo root with `gitleaks` and `bw` entries (source, version, binary, asset_template, os_map/arch_map, empty checksum placeholders for all four `<os>-<arch>` keys)
- [x] 1.2 Add `brew_install yq` and `brew_install bats-core` to `init.sh` next to the existing `brew_install` calls

## 2. gh_install script

- [x] 2.1 Create `gh_install` (executable, `#!/usr/bin/env bash`, `set -euo pipefail`) at the repo root
- [x] 2.2 Implement argument parsing: `<binary> [install_dir]`; default `install_dir` = `/usr/local/bin`; print usage on zero positional args
- [x] 2.3 Check `yq` is on `PATH`; exit non-zero with install hint (`brew install yq` / `apt install yq`) if missing
- [x] 2.4 Detect host OS via `uname -s` and normalize to `linux`/`darwin`; exit non-zero on anything else
- [x] 2.5 Detect host arch via `uname -m` and normalize `x86_64`/`amd64` → `amd64`, `aarch64`/`arm64` → `arm64`; exit non-zero on anything else
- [x] 2.6 Look up the binary key in `binaries.yaml`; exit non-zero with available keys list if missing
- [x] 2.7 Idempotency check: read `$HOME/.local/state/gh_install/installed.yaml`; if entry for `<binary>` matches registry `version`, print "already installed" and exit zero
- [x] 2.8 Resolve the asset URL by applying `os_map` / `arch_map` overrides and substituting `{source}`, `{version}`, `{os}`, `{arch}` into `asset_template`
- [x] 2.9 Read the expected checksum from `checksums.<os>-<arch>`; exit non-zero with "run get_checksums" hint if empty/missing
- [x] 2.10 Create a temp working dir via `mktemp -d` and register `trap 'rm -rf "$tmpdir"' EXIT`
- [x] 2.11 Download the asset into the temp dir with `curl -fsSL`; trap handles cleanup on any failure
- [x] 2.12 Compute the asset's SHA-256 (`shasum -a 256` on macOS, `sha256sum` on linux — pick whichever is on `PATH`) and compare against the registry value; print expected vs actual on mismatch and exit non-zero
- [x] 2.13 Extract `.tar.gz`/`.tgz` with `tar --no-same-owner -zxf`, `.zip` with `unzip -o`, raw binary by rename — all inside the temp dir
- [x] 2.14 `chmod +x` the extracted binary and `mv` it to `<install_dir>/<binary>`; if `install_dir` isn't writable, print a clear message and exit non-zero
- [x] 2.15 On successful install, create the state-file parent dir if missing and write `<binary>: <version>` to `installed.yaml` via `yq -i`
- [x] 2.16 Print "Installed <binary> <version> to <install_dir>/<binary>" on success

## 3. get_checksums script

- [x] 3.1 Create `get_checksums` (executable, `#!/usr/bin/env bash`, `set -euo pipefail`) at the repo root
- [x] 3.2 Check `yq` and `curl` are on `PATH`; exit non-zero with install hint if missing
- [x] 3.3 Iterate every top-level binary key in `binaries.yaml` via `yq`
- [x] 3.4 For each entry, build the four resolvable `<os>-<arch>` asset filenames from `asset_template` + `os_map` + `arch_map`
- [x] 3.5 Locate the release's published checksums file by querying the GitHub releases API (`/repos/{source}/releases/tags/v{version}` or the bare version) and scanning asset names for `*.sha256`, then `SHA256SUMS`, then `checksums.txt`; warn and skip the entry if none found
- [x] 3.6 Download the checksums file and grep each resolved asset filename to extract its SHA-256
- [x] 3.7 For each found hash, write it back into `binaries.yaml` at `<binary>.checksums.<os>-<arch>` using `yq -i`
- [x] 3.8 Warn (don't fail) when a specific platform asset is absent from the located checksums file; leave that key's existing value untouched
- [x] 3.9 Print a summary at the end (binaries processed, hashes written, warnings)

## 4. Tests (bats-core)

- [x] 4.1 Create `tests/` directory layout: `tests/fixtures/`, `tests/helpers/`, `tests/gh_install.bats`, `tests/get_checksums.bats`, `tests/registry.bats`
- [x] 4.2 Build fixture archives: `tests/fixtures/gitleaks.tar.gz` (containing a fake `gitleaks` binary), `tests/fixtures/bw.zip` (containing a fake `bw` binary), and a `tests/fixtures/sha256sums.txt` with the matching hashes
- [x] 4.3 Write `tests/helpers/mock_curl.bash`: a PATH-shimmed `curl` that copies the requested URL's tail-segment from `tests/fixtures/` to the requested output path, and emits non-zero for unknown URLs
- [x] 4.4 Write `tests/helpers/setup.bash` exposing common `setup()` / `teardown()` that create a temp `HOME` (so `$HOME/.local/state/gh_install/installed.yaml` lands in the temp dir), a temp `INSTALL_DIR`, prepend the mock-curl shim to `PATH`, and stage a fixture `binaries.yaml`
- [x] 4.5 `gh_install.bats` — registry resolution: template substitution and `os_map`/`arch_map` overrides produce the right URL on `linux/amd64` and `darwin/arm64`
- [x] 4.6 `gh_install.bats` — OS/arch normalization: `Linux/x86_64`, `Linux/aarch64`, `Darwin/x86_64`, `Darwin/arm64` resolve correctly; `Linux/armv7l` exits non-zero
- [x] 4.7 `gh_install.bats` — checksum match: install succeeds, binary is at `INSTALL_DIR/<binary>`, state file has the version
- [x] 4.8 `gh_install.bats` — checksum mismatch: exits non-zero, install dir unchanged, temp dir gone, state file unchanged
- [x] 4.9 `gh_install.bats` — missing checksum: exits non-zero with "run get_checksums" hint, install dir unchanged
- [x] 4.10 `gh_install.bats` — idempotency: skip when state matches; reinstall when state version drifts; create state file on first install; reinstall after removing the binary's state entry
- [x] 4.11 `gh_install.bats` — unknown binary key: exits non-zero, lists available keys
- [x] 4.12 `gh_install.bats` — extraction failure leaves no files behind (corrupted fixture)
- [x] 4.13 `get_checksums.bats` — parses `*.sha256` / `SHA256SUMS` / `checksums.txt` and writes hashes into the fixture `binaries.yaml`
- [x] 4.14 `get_checksums.bats` — release with no published checksums file: warning + entry untouched + exit zero
- [x] 4.15 `get_checksums.bats` — one platform asset missing from a present checksums file: three values written, warning printed for the missing one, prior value preserved
- [x] 4.16 `registry.bats` — `binaries.yaml` parses with `yq`, every entry has the required keys (`source`, `version`, `binary`, `asset_template`, `checksums`), and every checksum value is either empty or a 64-char hex string
- [x] 4.17 Run `bats tests/` locally and confirm 100% pass; no test hits the network (verify by reviewing the mock and by `unset http_proxy; unset https_proxy` in `setup.bash`)

## 5. Cleanup of old scripts

- [x] 5.1 `grep -rn "gh-install.sh\|add-gitleaks\|add-bw" .` to find every reference
- [x] 5.2 Replace `init.sh` lines that invoke `add-bw` and `add-gitleaks` with `./gh_install bw` and `./gh_install gitleaks`
- [x] 5.3 Update any other references found in `.zshrc`, `README.md`, or anywhere else
- [x] 5.4 Delete `gh-install.sh`, `add-gitleaks`, `add-bw`

## 6. Documentation

- [x] 6.1 Rewrite `README.md` at the repo root with sections: What this repo is, Quick start (`./init.sh`), Binary registry (Install a binary, Add a new binary, Refresh checksums, Reinstall a binary, State file, Supported platforms, Unsupported releases), Run the tests
- [x] 6.2 Include the `binaries.yaml` schema example with comments next to each field
- [x] 6.3 Document the `<os>-<arch>` matrix: `linux-amd64`, `linux-arm64`, `darwin-amd64`, `darwin-arm64`

## 6.5 Registry extensions: per-platform asset_template overrides + checksums_template

- [x] 6.5.1 Update `gh_install` URL resolution: when `asset_template_overrides[<platform>]` is set and non-empty, use it as the template; when set and empty, exit non-zero with "binary does not support <platform>" before any download.
- [x] 6.5.2 Update `get_checksums` URL resolution to apply the same `asset_template_overrides` logic when computing the asset filename for each platform; silently skip platforms whose override is the empty string.
- [x] 6.5.3 Update `get_checksums` checksums-file selection: when `checksums_template` is set, fetch only that templated URL; do not consult the per-asset/`SHA256SUMS`/`checksums.txt` fallbacks for that entry. Warn-and-skip if the templated URL fails to fetch.
- [x] 6.5.4 Update `binaries.yaml`: add `checksums_template` to the gitleaks entry pointing at `https://github.com/{source}/releases/download/v{version}/gitleaks_{version}_checksums.txt`; add `asset_template_overrides` to the bw entry with empty-string entries for `linux-amd64` and `linux-arm64` (= unsupported).
- [x] 6.5.5 Update `tests/fixtures/binaries.yaml` to mirror the production registry's new fields.
- [x] 6.5.6 Add a fixture `gitleaks_8.16.4_checksums.txt` (parseable by `get_checksums`) for the `checksums_template` test.
- [x] 6.5.7 `gh_install.bats` — empty `asset_template_overrides` value: gh_install on that platform exits non-zero with "does not support" message and modifies nothing.
- [x] 6.5.8 `gh_install.bats` — non-empty `asset_template_overrides` value: gh_install resolves the override template (verify via curl log).
- [x] 6.5.9 `get_checksums.bats` — `checksums_template` is set: the script fetches the templated URL, parses it for all four platforms, and never requests `SHA256SUMS`/`checksums.txt`/per-asset `.sha256` URLs (verify via curl log).
- [x] 6.5.10 `get_checksums.bats` — empty `asset_template_overrides` value: the script silently skips that platform (no warning, no change).
- [x] 6.5.11 README: add a "Per-platform overrides" subsection documenting `asset_template_overrides` (with the bw example) and `checksums_template` (with the gitleaks example).

## 6.6 local_checksums_fallback (opt-in local hashing)

- [x] 6.6.1 Update `get_checksums`: after the existing upstream-checksum search completes, if the entry has `local_checksums_fallback: true`, for every active platform with no hash yet — download the resolved asset, compute SHA-256 locally, write to the registry, and print `computed locally <key>/<platform>` for each slot.
- [x] 6.6.2 If the local download fails, warn naming the platform and URL, leave the slot untouched, continue with remaining platforms.
- [x] 6.6.3 Increment `warnings` and never claim a slot is "computed locally" when the download failed — keep summary numbers honest.
- [x] 6.6.4 Update `binaries.yaml`: set `local_checksums_fallback: true` on the bw entry (bitwarden doesn't publish a checksums file).
- [x] 6.6.5 Update README "Per-platform overrides" section to document `local_checksums_fallback` with the bw example, including the trust caveat ("registry no longer reflects upstream-stated hashes").
- [x] 6.6.6 `get_checksums.bats` — `local_checksums_fallback: true` + no hosted checksums: all platforms get computed hashes from the asset bytes, "computed locally" notice printed for each.
- [x] 6.6.7 `get_checksums.bats` — `local_checksums_fallback: true` + asset download fails for one platform: that platform warns and is left untouched, others complete normally.
- [x] 6.6.8 `get_checksums.bats` — `local_checksums_fallback` unset (default): existing warn-and-skip behavior preserved (no asset download attempted).

## 7. Verification

- [x] 7.1 Run `bats tests/` and confirm all tests pass
- [x] 7.2 Run `./get_checksums` and confirm `binaries.yaml` is populated with non-empty hashes for the platforms upstream publishes
- [x] 7.3 Delete state file (`rm -f ~/.local/state/gh_install/installed.yaml`); run `./gh_install gitleaks` on the current host; confirm `gitleaks --version` reports `v8.16.4` and the state file now records `gitleaks: 8.16.4`
- [x] 7.4 Re-run `./gh_install gitleaks` immediately; confirm it prints "already installed" and exits zero without touching `INSTALL_DIR`
- [x] 7.5 Run `yq -i 'del(.gitleaks)' ~/.local/state/gh_install/installed.yaml` then `./gh_install gitleaks`; confirm a real install happens and the state file is rewritten with `gitleaks: 8.16.4`
- [x] 7.6 Run `./gh_install bw`; confirm `bw --version` reports `2026.2.0`
- [x] 7.7 Manually corrupt the registry checksum, remove the gitleaks state entry, then run `./gh_install gitleaks`; confirm script exits non-zero, prints expected vs actual, leaves no temp files, and the state file has no `gitleaks` entry
- [x] 7.8 Blank the registry checksum, remove the gitleaks state entry, then run `./gh_install gitleaks`; confirm script exits non-zero with the "run get_checksums" hint
- [x] 7.9 Run `./gh_install nonexistent`; confirm the script exits non-zero and lists `gitleaks` and `bw` as available keys
