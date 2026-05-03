### Requirement: Binary registry file

The system SHALL maintain a single YAML registry file (`binaries.yaml`) at the repo root that lists every binary the user wants installable. Each entry SHALL include:

- A top-level binary key (the canonical short name used as the `gh_install` argument).
- `source`: the GitHub `owner/repo` slug.
- `version`: the release tag or version string.
- `binary`: the binary filename to install (the file extracted from the asset and placed on `PATH`).
- `asset_template`: a URL or filename template containing `{source}`, `{version}`, `{os}`, and `{arch}` tokens that resolves to the release asset.
- `asset_template_overrides` (optional): a mapping from `<os>-<arch>` keys to per-platform URL templates, used when an upstream's filename pattern differs across platforms (e.g., bitwarden's macOS assets use `bw-macos-{arch}-{version}.zip` while its Linux asset uses an entirely different name). The same `{source}`, `{version}`, `{os}`, `{arch}` tokens are supported. An empty-string override (`linux-amd64: ""`) explicitly marks the platform as unsupported for this binary; `gh_install` SHALL refuse to install it and `get_checksums` SHALL skip it silently (no warning).
- `os_map` (optional): a mapping from canonical OS names (`linux`, `darwin`) to the token to substitute for `{os}` (e.g., `darwin: macos`). When a key is omitted, the canonical name is used verbatim.
- `arch_map` (optional): a mapping from canonical arch names (`amd64`, `arm64`) to the token to substitute for `{arch}`. When a key is omitted, the canonical name is used verbatim.
- `checksums_template` (optional): a URL template for the release's published aggregate checksums file (e.g., `https://github.com/{source}/releases/download/v{version}/gitleaks_{version}_checksums.txt`). The same `{source}` and `{version}` tokens are supported (no `{os}`/`{arch}`, since this file is per-release). When set, `get_checksums` SHALL fetch this URL and use it as the authoritative source for that entry's checksums; the default search order (per-asset `*.sha256`, `SHA256SUMS`, `checksums.txt`) is not consulted.
- `local_checksums_fallback` (optional, boolean, default `false`): when `true`, `get_checksums` SHALL — for every platform that received no hash from any upstream source — download the asset directly and compute its SHA-256 locally, writing the result into the registry. Each locally-computed slot SHALL be logged with a clear "computed locally" notice so the trust degradation (registry no longer reflects upstream-stated hashes) is visible to the user. The default `false` preserves the original "registry checksums always come from upstream" trust contract.
- `checksums`: a mapping from `<os>-<arch>` keys (e.g., `linux-amd64`, `darwin-arm64`) to SHA-256 hex strings.

#### Scenario: Registry contains gitleaks and bitwarden
- **WHEN** a user reads `binaries.yaml`
- **THEN** the file contains entries for `gitleaks` (source `gitleaks/gitleaks`, binary `gitleaks`) and `bw` (source `bitwarden/clients`, binary `bw`), each with version, asset template, and four `<os>-<arch>` checksum entries

#### Scenario: Asset template tokens substitute correctly
- **WHEN** `gh_install` resolves the gitleaks asset URL on linux/amd64 with template `https://github.com/gitleaks/gitleaks/releases/download/v{version}/gitleaks_{version}_{os}_{arch}.tar.gz` and `arch_map: {amd64: x64}`
- **THEN** the resolved URL is `https://github.com/gitleaks/gitleaks/releases/download/v8.16.4/gitleaks_8.16.4_linux_x64.tar.gz`

#### Scenario: Per-platform asset_template override is used when set
- **WHEN** an entry has `asset_template: ".../bw-{os}-{arch}-{version}.zip"` and `asset_template_overrides.linux-amd64: ".../bw-oss-{version}.zip"`
- **AND** `gh_install` runs on linux/amd64
- **THEN** the resolved URL uses the override template (resulting in `.../bw-oss-2026.2.0.zip`), not the default

#### Scenario: Empty-string override marks platform unsupported for that binary
- **WHEN** an entry has `asset_template_overrides.linux-amd64: ""`
- **AND** `gh_install` runs on linux/amd64 for that binary
- **THEN** the script exits non-zero with a message stating the binary does not support `linux-amd64`, makes no download, and does not modify the install directory or state file

#### Scenario: checksums_template overrides default checksums-file search
- **WHEN** an entry has `checksums_template: "https://github.com/{source}/releases/download/v{version}/gitleaks_{version}_checksums.txt"`
- **AND** the user runs `./get_checksums`
- **THEN** the script fetches the templated URL and parses it for each platform's filename, and does not attempt the default `*.sha256` / `SHA256SUMS` / `checksums.txt` search

### Requirement: gh_install host detection

The `gh_install` script SHALL detect the host OS and CPU architecture and normalize them to canonical tokens before looking up the registry.

- OS detection SHALL produce `linux` for Linux hosts and `darwin` for macOS hosts.
- Arch detection SHALL produce `amd64` for `x86_64` / `amd64` hosts and `arm64` for `aarch64` / `arm64` hosts.
- If the host OS or arch cannot be normalized to one of the supported values, the script SHALL exit non-zero with a message naming the unsupported value.

#### Scenario: Linux x86_64 host
- **WHEN** `gh_install` runs on a host where `uname -s` returns `Linux` and `uname -m` returns `x86_64`
- **THEN** the script uses `os=linux` and `arch=amd64` for registry lookup

#### Scenario: macOS Apple Silicon host
- **WHEN** `gh_install` runs on a host where `uname -s` returns `Darwin` and `uname -m` returns `arm64`
- **THEN** the script uses `os=darwin` and `arch=arm64` for registry lookup

#### Scenario: Unsupported architecture
- **WHEN** `gh_install` runs on a host where `uname -m` returns `armv7l`
- **THEN** the script exits non-zero with a message indicating the architecture is unsupported and no download is attempted

### Requirement: gh_install checksum verification

The `gh_install` script SHALL verify the SHA-256 of the downloaded asset against the value stored in the registry under the matching `<os>-<arch>` key BEFORE extracting or installing.

- If the registry has no checksum entry for the resolved `<os>-<arch>`, the script SHALL exit non-zero, MUST NOT extract or install, and SHALL delete the downloaded asset.
- If the computed SHA-256 does not match the registry value, the script SHALL exit non-zero, MUST NOT extract or install, and SHALL delete the downloaded asset.
- Only after a successful match SHALL the script extract (for `.tar.gz`/`.tgz`/`.zip`) or rename (for raw binaries), make the binary executable, and move it to the install directory.

#### Scenario: Checksum matches
- **WHEN** the downloaded asset's SHA-256 equals the registry value for the resolved `<os>-<arch>`
- **THEN** the script extracts the binary, makes it executable, and installs it to the configured install directory

#### Scenario: Checksum mismatch
- **WHEN** the downloaded asset's SHA-256 differs from the registry value
- **THEN** the script prints both expected and actual hashes, deletes the downloaded asset, leaves no extracted files behind, and exits non-zero

#### Scenario: No checksum recorded
- **WHEN** the registry has no `checksums.<os>-<arch>` entry for the resolved platform
- **THEN** the script exits non-zero with a message instructing the user to run `get_checksums`, deletes any downloaded asset, and does not install the binary

### Requirement: gh_install failure cleanup

On any failure between download start and successful install (download error, extraction error, checksum mismatch, missing checksum, unsupported platform), `gh_install` SHALL remove every file it created during this invocation (downloaded archive, extracted binary, partial files) before exiting non-zero.

#### Scenario: Download fails mid-transfer
- **WHEN** `curl` exits non-zero while downloading the asset
- **THEN** the partial download file is deleted and the script exits non-zero

#### Scenario: Extraction fails
- **WHEN** the archive is corrupt and `tar` or `unzip` exits non-zero after a successful checksum match
- **THEN** both the downloaded archive and any partially extracted binary file are deleted and the script exits non-zero

### Requirement: gh_install idempotency

The `gh_install` script SHALL maintain a state file at `$HOME/.local/state/gh_install/installed.yaml` recording which version of each binary has been installed by this script. Before downloading an asset, the script SHALL read the state file and, if the recorded version for the requested binary matches the registry's `version` for that binary, exit zero with a message indicating the binary is already installed at the requested version. After a successful install, the script SHALL update the state file's `<binary>` key to the registry version that was just installed.

- The state file SHALL be created (with parent directories) on the first successful install if it does not exist.
- If the state file is missing, malformed, or has no entry for the requested binary, the script SHALL proceed with installation (no error).
- To reinstall a binary at the same version, the user removes that binary's entry from the state file (e.g., `yq -i 'del(.gitleaks)' "$state_file"`); on the next run the script proceeds with installation. The script does NOT provide a force flag.

#### Scenario: Already at requested version
- **WHEN** the state file records `gitleaks: 8.16.4` and the registry's `gitleaks.version` is `8.16.4`
- **AND** the user runs `./gh_install gitleaks`
- **THEN** the script prints "gitleaks 8.16.4 is already installed", does not download, does not modify the install directory, and exits zero

#### Scenario: Version drift triggers reinstall
- **WHEN** the state file records `gitleaks: 8.15.0` and the registry's `gitleaks.version` is `8.16.4`
- **AND** the user runs `./gh_install gitleaks`
- **THEN** the script proceeds with download, verify, install, and on success rewrites the state file's `gitleaks` key to `8.16.4`

#### Scenario: First install creates state file
- **WHEN** the state file does not yet exist and the user runs `./gh_install gitleaks` for the first time
- **THEN** after successful install the state file exists at `$HOME/.local/state/gh_install/installed.yaml` with `gitleaks: 8.16.4`

#### Scenario: Reinstall by removing state entry
- **WHEN** the state file records `gitleaks: 8.16.4` and the user removes the `gitleaks` key from the state file, then runs `./gh_install gitleaks`
- **THEN** the script proceeds with download, verify, install, and rewrites the state file's `gitleaks` key to `8.16.4`

### Requirement: gh_install CLI surface

The `gh_install` script SHALL accept the following CLI shape: `gh_install <binary> [install_dir]`.

- `<binary>` is a positional argument: the binary key from the registry. Required.
- `install_dir` is an optional positional argument; when omitted, it SHALL default to `/usr/local/bin`.
- If invoked with zero positional arguments or with a binary key not present in the registry, the script SHALL exit non-zero with a usage message and (for unknown keys) the list of available binary keys.

#### Scenario: Install a known binary
- **WHEN** the user runs `./gh_install gitleaks`
- **THEN** the script reads the gitleaks entry from `binaries.yaml`, downloads the matching asset for the host, verifies the checksum, and installs `gitleaks` to `/usr/local/bin`

#### Scenario: Unknown binary key
- **WHEN** the user runs `./gh_install nonexistent`
- **THEN** the script exits non-zero, prints a message that `nonexistent` is not in the registry, and lists the available binary keys

#### Scenario: Custom install directory
- **WHEN** the user runs `./gh_install gitleaks ~/bin`
- **THEN** the script installs the gitleaks binary to `~/bin` instead of `/usr/local/bin`

### Requirement: get_checksums refresh

The `get_checksums` script SHALL iterate every binary in `binaries.yaml`, fetch the release's published checksums file from GitHub for the entry's `version`, parse the SHA-256 for each of the four `<os>-<arch>` assets the registry can resolve, and write the values back into the registry's `checksums.<os>-<arch>` keys.

- If the entry has a `checksums_template`, the script SHALL fetch that URL exclusively as the authoritative checksums file and SHALL NOT consult the default search order. If the templated URL fails to fetch, the script SHALL warn and skip the entry.
- Otherwise the script SHALL look for the published checksums file by trying the release's assets in order: a file matching `*.sha256` adjacent to the asset, then `SHA256SUMS`, then `checksums.txt`.
- For each `<os>-<arch>` resolvable from the entry's `asset_template` (or its per-platform override in `asset_template_overrides`) plus `os_map`/`arch_map`, the script SHALL match the resolved asset filename against lines in the checksums file and extract the SHA-256.
- Platforms whose `asset_template_overrides` value is the empty string SHALL be skipped silently (no warning, no value written).
- If a published checksums file cannot be located for a release, OR if a specific asset filename is not found within the located checksums file, the script SHALL skip that entry/key with a warning and continue with the remaining entries; it SHALL NOT invent or guess checksum values.
- After processing all entries, `binaries.yaml` SHALL be rewritten with updated `checksums` blocks while preserving all other keys (including comments where the YAML library supports it).

#### Scenario: Refresh checksums for all binaries
- **WHEN** the user runs `./get_checksums`
- **THEN** for each entry in `binaries.yaml` the script downloads the published checksums file, extracts the four `<os>-<arch>` SHA-256 values, and writes them into the entry's `checksums` block

#### Scenario: Release has no published checksums file
- **WHEN** an entry's release exposes no `*.sha256`, `SHA256SUMS`, or `checksums.txt` asset
- **THEN** the script prints a warning naming the entry, leaves that entry's existing checksums untouched, and continues with the next entry

#### Scenario: Specific platform asset missing from checksums file
- **WHEN** the published checksums file lists three of the four resolvable assets but is missing one
- **THEN** the script writes the three found values, prints a warning naming the missing `<os>-<arch>` key, leaves that single key's previous value untouched, and exits zero overall (warnings only)

#### Scenario: Local checksums fallback fills gaps when opted in
- **WHEN** an entry has `local_checksums_fallback: true` and upstream provides no checksums for any platform (no `*.sha256`, `SHA256SUMS`, `checksums.txt`, or `checksums_template`)
- **AND** the user runs `./get_checksums`
- **THEN** for every active platform the script downloads the resolved asset, computes its SHA-256 locally, writes the result to the registry, and prints a "computed locally" notice for each slot

#### Scenario: Local checksums fallback download failure
- **WHEN** an entry has `local_checksums_fallback: true` and the upstream asset URL returns non-200 for one platform
- **THEN** that platform's checksum is left untouched, a warning naming the platform and URL is printed, and the script continues with the remaining platforms

#### Scenario: Local checksums fallback NOT enabled (default)
- **WHEN** an entry omits `local_checksums_fallback` (or sets it to `false`) and upstream provides no checksums
- **THEN** the script SHALL NOT download assets to compute hashes; existing behavior (warn-and-skip) is preserved
