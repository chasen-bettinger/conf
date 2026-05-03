# conf

My machine-config repo. Holds dotfiles, install scripts, and a small registry-driven installer for binaries pulled from GitHub releases.

## Quick start

```sh
./init.sh
```

Symlinks `.zshrc` and `CLAUDE.md` into place, installs Homebrew packages (`atuin`, `nono`, `gh`, `kubeconform`, `yq`, `bats-core`), clones oh-my-zsh plugins listed in `oh-my-zsh-plugins/plugins.txt`, and runs `gh_install bw` and `gh_install gitleaks` if those binaries aren't already present.

## Binary registry

`binaries.yaml` is the single source of truth for which GitHub-released binaries this repo installs. Two scripts work against it:

- `gh_install <binary>` — install a binary by its registry key.
- `get_checksums` — refresh the registry's per-platform SHA-256 values from upstream release metadata.

### `binaries.yaml` schema

```yaml
gitleaks:                                 # registry key (= argument to gh_install)
  source: gitleaks/gitleaks               # GitHub owner/repo
  version: 8.16.4                         # release version (no leading 'v'; the template adds it)
  binary: gitleaks                        # filename to extract and put on PATH
  asset_template: >-                      # URL with {source}, {version}, {os}, {arch} tokens
    https://github.com/{source}/releases/download/v{version}/gitleaks_{version}_{os}_{arch}.tar.gz
  arch_map:                               # optional per-binary arch token rewrites
    amd64: x64                            # gh_install canonicalizes to amd64; gitleaks uses x64
  os_map:                                 # optional per-binary os token rewrites (e.g. darwin -> macos)
  checksums_template: >-                  # optional; URL to an aggregate per-release checksums file
    https://github.com/{source}/releases/download/v{version}/gitleaks_{version}_checksums.txt
  checksums:                              # required; populate with ./get_checksums
    linux-amd64: 4166458d...702e
    linux-arm64: ""
    darwin-amd64: ""
    darwin-arm64: 4ac90876...b869
```

### Per-platform overrides

Two optional fields cover upstreams that don't fit one tidy template.

**`asset_template_overrides`** — a per-platform override for `asset_template`. Use it when an upstream uses different filename schemes per OS/arch. An empty-string value marks that platform as unsupported for this binary; `gh_install` refuses to run there and `get_checksums` silently skips the slot.

```yaml
bw:
  source: bitwarden/clients
  version: 2026.2.0
  binary: bw
  asset_template: "https://github.com/{source}/releases/download/cli-v{version}/bw-{os}-{arch}-{version}.zip"
  asset_template_overrides:
    linux-amd64: ""             # bitwarden's Linux assets use a different scheme; populate when needed
    linux-arm64: ""
  os_map:
    darwin: macos
```

**`checksums_template`** — a URL template for the release's aggregate checksums file. Use it when the upstream's checksums file isn't named `*.sha256`, `SHA256SUMS`, or `checksums.txt`. When set, `get_checksums` fetches only this URL for that entry; the default search order is not consulted.

```yaml
gitleaks:
  ...
  checksums_template: "https://github.com/{source}/releases/download/v{version}/gitleaks_{version}_checksums.txt"
```

**`local_checksums_fallback`** — boolean, default `false`. When `true`, `get_checksums` will — for any platform that found no upstream-provided hash — download the asset directly and compute its SHA-256 locally, writing the result to the registry. Use it for upstreams that publish no checksums file at all (bitwarden's CLI is the motivating case).

```yaml
bw:
  ...
  local_checksums_fallback: true
```

Trust caveat: with the fallback enabled, the registry's checksums for that entry no longer reflect upstream-stated hashes — they reflect what your local network delivered when `get_checksums` ran. Verification at install time still catches drift between then and now, but the baseline is weaker than the strict-upstream contract. The script prints `computed locally <key>/<platform>` for every slot it fills this way so the trust degradation is visible.

Token support: `asset_template_overrides` values support `{source}`/`{version}`/`{os}`/`{arch}`; `checksums_template` supports `{source}`/`{version}` only (the file is per-release, not per-platform); `local_checksums_fallback` is a plain boolean.

### Install a binary

```sh
./gh_install gitleaks                       # installs to /usr/local/bin
./gh_install gitleaks ~/bin                 # custom install dir
```

`gh_install` is idempotent: if the state file (see below) already records the registry's version, the script prints "already installed" and exits zero without downloading.

### Add a new binary

1. Append an entry to `binaries.yaml` with `source`, `version`, `binary`, `asset_template`, and four empty `checksums` slots.
2. Run `./get_checksums` to fill in the SHA-256 values from upstream.
3. Run `./gh_install <new-key>` to verify it installs.
4. Commit `binaries.yaml`.

### Refresh checksums

After bumping a `version`:

```sh
./get_checksums
git diff binaries.yaml          # confirm only checksum lines changed
git commit -am "bump <binary> to <new-version>"
```

`get_checksums` looks for the release's published checksum file in this order: per-asset `*.sha256` sidecars, then `SHA256SUMS`, then `checksums.txt`. If none exist for a release, it warns and leaves that entry's checksums untouched — you'll need to populate them manually or skip that release.

### Reinstall a binary

`gh_install` will skip a binary that's already at the registry version. To force a reinstall (e.g. to repair a corrupted file):

```sh
yq -i 'del(.gitleaks)' ~/.local/state/gh_install/installed.yaml
./gh_install gitleaks
```

### State file

- Path: `~/.local/state/gh_install/installed.yaml`
- Contents: a flat `binary: version` map of what `gh_install` has installed on this machine.
- Inspect: `cat ~/.local/state/gh_install/installed.yaml`
- Per-machine; not checked into the repo.

The state file is rewritten only on a successful install. A failed install never touches it, so the recorded version always reflects what's actually on disk (modulo external tampering).

### Supported platforms

The installer supports four `<os>-<arch>` combinations:

| OS     | Arch  | Key            |
| ------ | ----- | -------------- |
| Linux  | amd64 | `linux-amd64`  |
| Linux  | arm64 | `linux-arm64`  |
| macOS  | amd64 | `darwin-amd64` |
| macOS  | arm64 | `darwin-arm64` |

`gh_install` normalizes `uname -m` (`x86_64`/`amd64` → `amd64`, `aarch64`/`arm64` → `arm64`) and exits non-zero on anything else. Use `arch_map` and `os_map` in the registry when an upstream uses different tokens (e.g. gitleaks publishes `x64` instead of `amd64`; bitwarden publishes `macos` instead of `darwin`).

### Unsupported releases

If an upstream repo doesn't publish a checksums file in a recognizable form, `get_checksums` warns and skips that entry. You then have two options:

1. Manually compute and paste in the SHA-256s. Acceptable but breaks the audit trail (the values are no longer derivable from upstream metadata).
2. Skip that binary in this repo and install it via another channel (Homebrew, distro package, nix).

## Run the tests

```sh
bats tests/*.bats
```

The test suite is hermetic — it shims `curl` and `uname` via `PATH`, points `HOME` at a temp directory, and serves fixture archives from `tests/fixtures/`. No tests hit the network.
