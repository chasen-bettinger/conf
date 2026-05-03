## Why

Adding a new GitHub-released binary to this conf repo currently requires hand-writing a per-binary wrapper (`add-gitleaks`, `add-bw`) that hardcodes the OS/arch branching, asset URLs, and SHA-256 checksums. This duplicates logic across every wrapper and makes upgrades a manual hunt for the right release URL and hash. A central registry keyed by `binary` lets the install logic live in one place and turns "add a new binary" into "append a few lines to a YAML file."

## What Changes

- Add `binaries.yaml` at the repo root — a YAML registry listing each binary with its `source` (owner/repo), `version`, `binary` name, asset URL template, and per-OS/arch SHA-256 checksums.
- Add `gh_install` — a script that takes a binary name, looks it up in the registry, detects the host OS and arch, downloads the asset, verifies the checksum against the registry-stored value, and installs the binary. The script SHALL be idempotent: if a state file records the same `binary → version` already installed, it skips the download and exits zero. To reinstall, the user removes the entry from the state file. On any failure (download, checksum mismatch, missing checksum, extraction) it deletes all downloaded artifacts and exits non-zero.
- Add `get_checksums` — a script that iterates every entry in the registry, fetches the release's published checksums file from GitHub (e.g., `*.sha256`, `SHA256SUMS`, `checksums.txt`, or a registry-supplied `checksums_template`), parses the SHA-256 for each OS/arch asset, and writes them back into `binaries.yaml`. For binaries whose upstream publishes no checksums file at all, the registry can opt in per-binary (`local_checksums_fallback: true`) to have `get_checksums` download the asset and compute the hash locally — a deliberate, visible trust degradation that's off by default.
- Add a `tests/` directory with `bats-core` unit tests covering registry resolution, OS/arch normalization, checksum verification (match, mismatch, missing), idempotency, and failure cleanup. Tests use fixture archives and mocked `curl` — they MUST NOT hit the network.
- Update `init.sh` — add `brew_install yq` and `brew_install bats-core` next to the existing `brew_install` calls so `gh_install` and the test suite have their dependencies on a fresh machine; replace the `add-bw` / `add-gitleaks` invocations with `./gh_install bw` and `./gh_install gitleaks`.
- Update `README.md` — add a usage section ("install a binary", "add a new binary to the registry", "refresh checksums", "run tests") and a maintenance section (state file location, supported platforms, what to do when an upstream release lacks a checksums file).
- **BREAKING** Remove `gh-install.sh`, `add-gitleaks`, and `add-bw`. Their gitleaks and bitwarden entries move into the registry; users invoke `./gh_install gitleaks` or `./gh_install bw` instead.

## Capabilities

### New Capabilities
- `gh-install-registry`: Registry-driven installation of GitHub-released binaries with checksum verification, plus a companion script that refreshes checksums from upstream release metadata.

### Modified Capabilities
<!-- None — no existing specs in openspec/specs/. -->

## Impact

- Affected files: new `binaries.yaml`, new `gh_install`, new `get_checksums`, new `tests/` directory with bats files and fixtures, updated `init.sh`, updated `README.md`; removal of `gh-install.sh`, `add-gitleaks`, `add-bw`.
- New runtime dependency: `yq` (YAML parser) — added to `init.sh` via `brew_install yq` so it's installed on `init.sh` runs.
- New dev/test dependency: `bats-core` — added to `init.sh` via `brew_install bats-core`.
- New persistent state: `~/.local/state/gh_install/installed.yaml` — tracks installed `binary → version` for idempotency.
- Existing dependencies still required: `curl`, `shasum`/`sha256sum`, `tar`, `unzip`.
