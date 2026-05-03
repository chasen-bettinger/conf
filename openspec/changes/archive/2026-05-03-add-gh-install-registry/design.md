## Context

Today, this conf repo has one low-level installer (`gh-install.sh`) that takes an explicit URL, SHA-256, and binary name, plus per-binary wrappers (`add-gitleaks`, `add-bw`) that hardcode the OS/arch branching and resolve to a `gh-install.sh` call. Adding a new binary means writing a new wrapper and copying release URLs and hashes by hand. The two existing wrappers already disagree on style (`add-gitleaks` branches on `uname -s`, `add-bw` branches on `uname -m` and only handles macOS), which signals the pattern doesn't scale. A registry-driven entry point fixes both the duplication and the inconsistency.

The user has chosen, up front, four shape decisions that frame this design:
1. Registry stores per-binary URL templates with token substitution.
2. `get_checksums` fetches the release's published checksums file (no fallback to local hashing).
3. Registry format is YAML, parsed via `yq`.
4. The new `gh_install` replaces `gh-install.sh`, `add-gitleaks`, and `add-bw`.

## Goals / Non-Goals

**Goals:**
- One file (`binaries.yaml`) is the single source of truth for which binaries the user wants and at what versions.
- Adding a new binary is a YAML edit + one `./get_checksums` run; no shell code changes required for a new entry that fits the template model.
- Checksum verification is mandatory and atomic — a missing or mismatched checksum produces no installed binary and no leftover files.
- Two scripts only (`gh_install`, `get_checksums`) to keep the surface tiny and the flow obvious.

**Non-Goals:**
- Auto-discovering new releases (Renovate/Dependabot territory; out of scope).
- Supporting Windows or non-x86/non-arm architectures (linux+darwin × amd64+arm64 only).
- Parallel installs of multiple binaries in one invocation (`gh_install` installs one binary per call).
- Compiling from source, symlink-versioning (`/usr/local/bin/gitleaks-8.16.4`), or tracking what's currently installed.
- Auto-falling back to local hashing if a release publishes no checksums file. Per user decision, the script warns and skips.

## Decisions

### Registry shape — single YAML file with templates

```yaml
gitleaks:
  source: gitleaks/gitleaks
  version: 8.16.4
  binary: gitleaks
  asset_template: "https://github.com/{source}/releases/download/v{version}/gitleaks_{version}_{os}_{arch}.tar.gz"
  arch_map:
    amd64: x64
  checksums:
    linux-amd64: 4166458d288be6453a9485665b8b5e6a50e6e29300207eb84fcb375c6b32702e
    linux-arm64: ""
    darwin-amd64: ""
    darwin-arm64: 4ac90876951f79341a76c61e847394c25895a5c5bbf316453757f7b48651b869

bw:
  source: bitwarden/clients
  version: 2026.2.0
  binary: bw
  asset_template: "https://github.com/{source}/releases/download/cli-v{version}/bw-{os}-{arch}-{version}.zip"
  os_map:
    darwin: macos
  checksums:
    linux-amd64: ""
    linux-arm64: ""
    darwin-amd64: 60cc5109b1cdad560231e02098f1ab2d16efa821d51c6ec089cb5c3cc351b2e5
    darwin-arm64: 63c736b74620280e422ce238bdbcbc267689a0ff831168959ef2124588fcc1e5
```

Tokens supported in `asset_template`: `{source}`, `{version}`, `{os}`, `{arch}`. `os_map` and `arch_map` rewrite the canonical token before substitution. Empty-string checksums are valid placeholders that `gh_install` treats as "no checksum recorded" (refuse to install) and that `get_checksums` will populate.

**Alternatives considered:**
- One `.sh` file per binary that sources a shared library (status quo, evolved). Rejected: still encodes URLs in code, defeats the "one place to look" goal.
- TOML/JSON. Rejected: user explicitly chose YAML, and YAML's nested `checksums` map reads cleanly.
- A flat `<os>-<arch>` URL per entry instead of a template. Rejected: four URLs per binary that are 95% identical is exactly the duplication we're replacing.

### `get_checksums` strategy — published file by default, opt-in local-hash fallback

The script fetches each release's published checksums file (`*.sha256`, `SHA256SUMS`, `checksums.txt`, or a registry-provided `checksums_template`) and parses it. If none exists, it warns and skips that entry by default, leaving its current values untouched.

For repos that don't publish a checksums file at all (bitwarden's CLI is the motivating case), the registry can opt in per-binary via `local_checksums_fallback: true`. When set, `get_checksums` falls back to downloading the asset directly and computing its SHA-256 locally for any platform that didn't get an upstream-provided hash.

**Trust trade-off — and why it's opt-in:**
- With upstream checksums: the registry stores the hash *upstream stated*. Verification at install time confirms the bytes you're about to install are the bytes upstream signed off on.
- With local fallback: the registry stores the hash *we computed at registry-update time*. Verification at install time confirms the bytes match what we previously downloaded — meaningfully weaker, because a MITM at registry-update time gets baked in. (Verification at install time still catches drift between then and now, but the baseline is lower.)

Making it per-binary opt-in preserves the original strict contract for everything that *can* meet it, and pushes the user to consciously accept the weaker contract on a binary-by-binary basis. Each locally-computed slot is announced (`computed locally`) at run time so the trust degradation is visible.

**Alternatives considered:**
- Always download + hash locally. Rejected: silently weakens the trust model for binaries that *do* publish checksums.
- Try published-file first, transparently fall back. Rejected (initially): same silent weakening. Replaced by the opt-in model after experience showed bitwarden makes the strict-only stance unworkable in practice.
- Allow a separate `manual_checksums:` block where users hand-enter hashes. Rejected: same trust profile as local fallback, but more friction (user has to compute hashes themselves) and easier to forget on version bumps.

### YAML parsing tool — `yq`, installed by `init.sh`

The Mike Farah Go-based `yq` (`yq eval`, `yq -i`) is the reference implementation. It's a single static binary, available via Homebrew and most distro repos, and supports in-place edits cleanly.

`init.sh` already has a `brew_install` helper that's idempotent (skips if installed). We add `brew_install yq` next to the existing entries, so on a fresh machine `yq` is present before any `gh_install` invocation. Both `gh_install` and `get_checksums` still verify `yq` is on `PATH` at runtime and fail with a clear install hint if it isn't — defense in depth, not a substitute for `init.sh`.

**Alternatives considered:**
- Auto-install `yq` from inside `gh_install` if missing. Rejected: violates the user's "Do NOT install a package without soliciting my opinion first" preference, and `init.sh` is the right place for environment setup.
- Hand-rolled `awk`/`sed` parser. Rejected: brittle, and editing nested maps in place is exactly what `yq` is for.

### Idempotency — state file at `~/.local/state/gh_install/installed.yaml`

`gh_install` is idempotent: if the binary at the requested registry version is already installed, it skips the work and exits zero.

The naive approach is to invoke the installed binary with `--version` and string-match, but version-output formats vary wildly across binaries (some print `v8.16.4`, some print `gitleaks version 8.16.4`, some don't support `--version` at all). Instead, we maintain a tiny YAML state file that records what *this script* installed and at what version:

```yaml
# ~/.local/state/gh_install/installed.yaml
gitleaks: 8.16.4
bw: 2026.2.0
```

On install, `gh_install` reads this file (creating an empty one with parent dirs if missing), looks up the requested binary, and:
- If the recorded version matches the registry version → print "already installed" and exit zero.
- If the recorded version differs (drift) → proceed with reinstall, then write the new version on success.
- If there's no entry → proceed with install, then write the new entry on success.

To reinstall at the same version (e.g., to repair a corrupted file or to re-verify), the user deletes the entry from the state file: `yq -i 'del(.<binary>)' ~/.local/state/gh_install/installed.yaml`. The next run sees no entry and proceeds with install. There is no `--force` flag — the state file *is* the source of truth, and editing it directly keeps the surface area small. The state file is written *after* successful install, so a mid-flight failure leaves the previous record untouched.

**Why `~/.local/state/gh_install/installed.yaml`:** Living under `~/.local/state` keeps the home directory uncluttered (no top-level `~/.gh_install` dotfile) and keeps machine-specific state out of the repo (the file is per-machine, not per-checkout). The path is hardcoded — no `XDG_STATE_HOME` env-var plumbing — because in single-user personal-machine usage the override buys nothing and adds confusion.

**Alternatives considered:**
- Run `<binary> --version` and parse. Rejected: unreliable across the binary zoo we plan to register.
- Hash the installed file vs. an "installed binary" hash in the registry. Rejected: requires `get_checksums` to download + extract every asset to compute the *binary* hash (we currently store only the *archive* hash from upstream).
- Drop a sentinel file like `<install_dir>/.gh_install/<binary>.<version>`. Rejected: install dirs are often shared (e.g., `/usr/local/bin`) and we shouldn't be cluttering them with metadata.

### Failure cleanup — track-and-trap

`gh_install` keeps a list of files it created (in a temp dir under `mktemp -d`) and registers a `trap` on `EXIT` that `rm -rf`'s the temp dir. The temp dir is the working area; the binary is only `mv`'d to the install dir on the success path, after which the trap still fires harmlessly. This guarantees no leftover archives or extracted binaries on any failure path including `set -e` aborts.

**Alternatives considered:**
- Manual `rm` calls after each potential failure. Rejected: easy to miss a path; the existing `gh-install.sh` doesn't clean up the extracted file if a later step fails.

### Replacing the old scripts

`gh-install.sh`, `add-gitleaks`, and `add-bw` are deleted in this change. The gitleaks and bw entries are added to `binaries.yaml` so `./gh_install gitleaks` and `./gh_install bw` reproduce today's behavior. Anything in `init.sh` or `.zshrc` referencing the old script names will need to be updated as part of implementation.

### CLI shape

```
./gh_install <binary> [install_dir]    # default install_dir: /usr/local/bin
./get_checksums                        # rewrites binaries.yaml in place
```

No flags. To reinstall a binary, the user removes its entry from the state file (`yq -i 'del(.<binary>)' ~/.local/state/gh_install/installed.yaml`) and re-runs. This keeps the CLI surface tiny and avoids accreting flags that would only exist for debugging.

### Testing — `bats-core` with mocked `curl`

Bash test framework is `bats-core` (https://github.com/bats-core/bats-core), the de facto standard for shell testing. It's a single static install via Homebrew or apt.

Tests live under `tests/` at the repo root:
```
tests/
  fixtures/                      # fake archives, sample checksums files
    gitleaks.tar.gz
    bw.zip
    sha256sums.txt
  helpers/
    mock_curl.bash               # PATH-shimmed curl that serves fixtures
    setup.bash                   # common setup/teardown
  gh_install.bats                # tests for gh_install
  get_checksums.bats             # tests for get_checksums
  registry.bats                  # tests for binaries.yaml shape & yq access
```

Tests are hermetic: they shim `curl` via `PATH` to serve fixture files, point `HOME` at a temp directory (so the script's `$HOME/.local/state/gh_install/installed.yaml` resolves under that temp dir), point install_dir at a temp directory, and use a fixture `binaries.yaml`. They MUST NOT make network calls. A single `bats tests/` run executes the whole suite.

**Coverage targets** (one test per scenario in the spec, plus implementation-level tests for parsing and shimming):
- Registry resolution (template substitution + os_map/arch_map).
- OS/arch normalization across `Linux/x86_64`, `Linux/aarch64`, `Darwin/x86_64`, `Darwin/arm64`, and one unsupported case.
- Checksum match → install succeeds.
- Checksum mismatch → cleanup, exit non-zero, install dir unchanged.
- Missing checksum → cleanup, exit non-zero with "run get_checksums" hint.
- Idempotency: skip when state matches; reinstall when state drifts; create state file on first install; reinstall when state entry is removed.
- Failure cleanup: trap removes temp dir on every error path.
- `get_checksums`: parse `*.sha256`, `SHA256SUMS`, `checksums.txt`; warn-and-skip when none found; warn-and-skip when one platform asset is absent.

**Alternatives considered:**
- `shellspec` (BDD-style). Rejected: more featureful than we need; `bats-core` is enough.
- `shunit2`. Rejected: development is much slower; `bats-core` has the larger ecosystem.
- Hand-rolled test scripts. Rejected: rebuilds what `bats-core` already gives us (assertions, `setup`/`teardown`, parallelism).

### Documentation — `README.md` at repo root

The current `README.md` is a single word ("test"). We rewrite it with:

1. **What this repo is** (one paragraph).
2. **Quick start**: `./init.sh` to provision a fresh machine.
3. **Binary registry** (the substantive new section):
   - **Install a binary**: `./gh_install <binary>` with examples (`./gh_install gitleaks`).
   - **Add a new binary**: append to `binaries.yaml` (show the schema), run `./get_checksums`, run `./gh_install <new-binary>` to verify.
   - **Refresh checksums**: when bumping `version`, run `./get_checksums` then commit `binaries.yaml`.
   - **Reinstall a binary**: remove its entry from the state file (`yq -i 'del(.<binary>)' ~/.local/state/gh_install/installed.yaml`) and re-run `./gh_install <binary>`.
   - **State file**: where it lives (`~/.local/state/gh_install/installed.yaml`), what it contains, how to inspect it, how to clear individual entries.
   - **Supported platforms**: `linux-amd64`, `linux-arm64`, `darwin-amd64`, `darwin-arm64`.
   - **Unsupported releases**: behavior when upstream doesn't publish a checksums file (warn + skip in `get_checksums`; install fails until a checksum is supplied manually).
4. **Run the tests**: `bats tests/`.

Keeping the docs colocated with the scripts (single `README.md`) matches the small-scope preference. If sections grow, split later.

## Risks / Trade-offs

- **`yq` dependency** → Mitigation: `init.sh` calls `brew_install yq`, so on any machine that's been bootstrapped via `init.sh` it's already present. As defense in depth, both `gh_install` and `get_checksums` verify `yq` is on `PATH` at runtime and exit with a clear `brew install yq` / `apt install yq` hint if it isn't.
- **Releases without a published checksums file are unsupported** → Mitigation: documented in spec; user can either skip that binary or land a follow-up change to add a hash-locally fallback if it bites.
- **Asset templates can't model every release naming scheme** → Mitigation: `os_map`/`arch_map` overrides handle the common cases (`amd64`→`x64`, `darwin`→`macos`). For the harder cases — upstream uses entirely different filename patterns across platforms — `asset_template_overrides` lets the registry pin a different template per `<os>-<arch>`. An empty-string override marks the platform unsupported for that binary (gh_install errors before download; get_checksums silently skips). Bitwarden is the motivating example: macOS uses `bw-macos-{arch}-{version}.zip`, Linux uses a different naming scheme entirely.
- **Releases that publish a checksums file under a non-standard name** → Mitigation: `checksums_template` lets the registry name the checksums file URL directly. Gitleaks is the motivating example: the file is `gitleaks_{version}_checksums.txt`, which doesn't match the default search names (`*.sha256`, `SHA256SUMS`, `checksums.txt`).
- **Replacing existing scripts breaks any external caller of `gh-install.sh`** → Mitigation: only `add-gitleaks` and `add-bw` call it inside this repo; grep the repo for `gh-install.sh` references before deletion and update `init.sh`/`.zshrc` if needed.
- **Empty checksum strings are easy to miss in review** → Mitigation: `gh_install` treats empty/missing as a hard error (refuse to install), so a forgotten `get_checksums` run produces a loud failure rather than a silent skipped-verification install.

## Migration Plan

1. Land `binaries.yaml`, `gh_install`, `get_checksums` together with both existing binaries (gitleaks, bw) ported into the registry.
2. Run `./get_checksums` to populate hashes for all four `<os>-<arch>` slots that upstream publishes.
3. Verify `./gh_install gitleaks` and `./gh_install bw` produce the same installed binaries as the old wrappers on the user's current host.
4. Delete `gh-install.sh`, `add-gitleaks`, `add-bw` and update any references in `init.sh` / `.zshrc` / README.

Rollback: revert the commit. Old wrappers come back; no persistent state is changed outside the repo.

## Open Questions

- None at this time. Registry location is settled (repo root). Idempotency is settled (state file; reinstall by removing the entry).
