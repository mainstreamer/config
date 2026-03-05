# Deployment

Two independent distribution channels, both triggered by `make patch/minor/major`.

```
make patch (or minor / major)
  │
  ├─ LOCAL: bump version → commit → tag → make deploy (archive + sign + scp) → push
  │
  └─ CI (GitHub Actions): tag push triggers workflow
       └─ create GitHub release with tarball
       └─ update Homebrew formula in mainstreamer/homebrew-epicli
```

## Install Methods

| Method | Command | Source |
|--------|---------|--------|
| Direct | `curl -fsSL https://tldr.icu/i \| bash` | Server (tldr.icu) |
| Homebrew | `brew install mainstreamer/epicli/epicli` | GitHub release |

After Homebrew install, run `epicli` once to complete setup (install deps, create symlinks). This is a one-time bootstrap step.

---

## Release Flow

### What `make patch` does (same for `minor`/`major`)

Runs `scripts/bump-version.sh`:

1. Bumps `VERSION=` in `install.sh` and writes `latest` file
2. `git add install.sh latest && git commit -m "v$NEW"`
3. `git tag v$NEW`
4. `make deploy` — builds archive, signs, uploads to server
5. `git push && git push --tags` — triggers GitHub Actions

### Server deploy (`make deploy`, step 4)

Runs locally because it needs the signing key and SSH access.

```
make archive    → master.tar.gz (rsync + tar of repo)
make sign       → install.sh.sig + master.tar.gz.sig (Ed25519)
scp             → all files to root@do:/srv/dotfiles/
ssh             → copy versioned tarball (v$VERSION.tar.gz)
```

Files on server after deploy:

| Path | File |
|------|------|
| `/i` | `install.sh` |
| `/i.sig` | `install.sh.sig` |
| `/master.tar.gz` | `master.tar.gz` |
| `/master.tar.gz.sig` | `master.tar.gz.sig` |
| `/v$VERSION.tar.gz` | Versioned copy |
| `/v$VERSION.tar.gz.sig` | Versioned signature |
| `/latest` | Version string for `epicli check` |

### GitHub Actions (`.github/workflows/update-homebrew.yml`)

Triggered by tag push (`v*`):

1. Checks out repo at the tag
2. Creates tarball (`epicli-$VERSION.tar.gz`) — same as `make archive`
3. Creates GitHub release with tarball attached (uses `GITHUB_TOKEN`)
4. Computes SHA256 of the tarball
5. Clones `mainstreamer/homebrew-epicli`, updates `Formula/epicli.rb` with new URL + SHA256
6. Pushes updated formula (uses `HOMEBREW_TAP_TOKEN`)

---

## Prerequisites

### Local (one-time setup)

| Requirement | Purpose | Setup |
|-------------|---------|-------|
| Ed25519 signing key | Sign install.sh and tarball | See [SIGNING.md](SIGNING.md) |
| SSH access to server | `scp` + `ssh` to `root@do` | SSH key in `~/.ssh/` |
| Git remote | Push commits and tags | `git remote -v` to verify |

### GitHub (one-time setup)

| Requirement | Purpose | Setup |
|-------------|---------|-------|
| `HOMEBREW_TAP_TOKEN` secret | Push formula updates to homebrew-epicli repo | GitHub PAT with Contents:write on `mainstreamer/homebrew-epicli`, added as secret in `mainstreamer/config` → Settings → Secrets → Actions |
| `mainstreamer/homebrew-epicli` repo | Homebrew tap | Public repo with `Formula/epicli.rb` |

`GITHUB_TOKEN` is provided automatically by GitHub Actions — no setup needed.

### Creating the Homebrew PAT

1. github.com → Settings → Developer settings → Personal access tokens → Fine-grained tokens
2. Name: `homebrew-tap-updater`
3. Repository access: Only `mainstreamer/homebrew-epicli`
4. Permissions: Contents → Read and write
5. Copy token → add as `HOMEBREW_TAP_TOKEN` secret in `mainstreamer/config`

---

## Commands

```bash
make patch              # Bump patch (3.4.5 → 3.4.6), deploy, push
make minor              # Bump minor (3.4.5 → 3.5.0), deploy, push
make major              # Bump major (3.4.5 → 4.0.0), deploy, push

make deploy             # Server deploy only (archive + sign + scp)
make archive            # Create master.tar.gz
make sign               # Sign install.sh + master.tar.gz
make version            # Show current version
```

---

## Verification

After running `make patch`:

```bash
# Server
curl -fsSL https://tldr.icu/latest           # Should show new version

# GitHub
gh release list --repo mainstreamer/config   # Should show new release

# Homebrew (after Actions complete)
brew update
brew info mainstreamer/epicli/epicli         # Should show new version
```
