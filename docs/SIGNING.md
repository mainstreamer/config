# Code Signing

`install.sh` and `master.tar.gz` are signed with an Ed25519 key.
Every deploy produces `.sig` files that are verified automatically.

## Key locations

| File | Location | Committed? |
|------|----------|------------|
| Private key | `~/.epicli-signing.pem` | **No** — local only |
| Public key | Embedded in `install.sh` (`SIGNING_PUBLIC_KEY`) | Yes |
| Public key (authoritative) | GitHub Gist (`SIGNING_KEY_URL` in `install.sh`) | External |

## Workflow

```
make deploy
  └─ make archive        → master.tar.gz
  └─ make sign           → install.sh.sig + master.tar.gz.sig  (Ed25519)
  └─ scp                 → all files → server
```

## What gets verified

| Asset | Signature | When |
|-------|-----------|------|
| `install.sh` | `install.sh.sig` (`/i.sig`) | At startup, before anything runs |
| `master.tar.gz` | `master.tar.gz.sig` (`/master.tar.gz.sig`) | After download, before extraction |

## Public key trust chain

The installer prefers the Gist-hosted key over the embedded copy — a compromised
server cannot swap both `install.sh` and the independent Gist simultaneously.
The embedded key is a fallback for offline/air-gapped use.

## Rekeying (if key is lost or compromised)

```bash
# 1. Generate new key
openssl genpkey -algorithm ed25519 -out ~/.epicli-signing.pem
chmod 600 ~/.epicli-signing.pem

# 2. Export public key
openssl pkey -in ~/.epicli-signing.pem -pubout

# 3. Paste into install.sh SIGNING_PUBLIC_KEY variable
# 4. Update the GitHub Gist with the new public key
# 5. make deploy
```

## Manual verification

```bash
curl -fsSL https://tldr.icu/i     -o install.sh
curl -fsSL https://tldr.icu/i.sig -o install.sh.sig
curl -fsSL "$SIGNING_KEY_URL"     -o epicli.pub.pem

openssl pkeyutl -verify -pubin -inkey epicli.pub.pem \
  -sigfile install.sh.sig -rawin -in install.sh \
  && echo "OK" || echo "TAMPERED"
```

## Server (Caddy)

`tldr.icu` Caddyfile serves:

| Path | File |
|------|------|
| `/i` | `install.sh` |
| `/i.sig` | `install.sh.sig` |
| `/master.tar.gz` | `master.tar.gz` |
| `/master.tar.gz.sig` | `master.tar.gz.sig` |

## Threat model

**Protects against:** tampered files on server, CDN/mirror poisoning, HTTP MITM

**Does not protect against:** attacker with full server access (can replace files + sigs).
For that: pin the public key out-of-band (Gist, Homebrew formula, signed GitHub release).
