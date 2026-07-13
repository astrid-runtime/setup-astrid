# setup-astrid

A GitHub Action that installs the [Astrid](https://github.com/astrid-runtime/astrid) CLI
(`astrid`, `astrid-daemon`, `astrid-build`, `astrid-emit`) onto a CI runner and puts it on
`PATH` — so a later step can run `astrid capsule check`, build a capsule, or anything else,
in one line.

It is **verified by default**: the released `SHA256SUMS.txt` is checked against the release's
keyless [sigstore](https://www.sigstore.dev/) signature (provenance, bound to the Astrid
release workflow's identity), and the downloaded archive is checked against those sums
(integrity). Nothing runs until both pass.

## Usage

```yaml
- uses: astrid-runtime/setup-astrid@v2
- run: astrid capsule check
```

Pin a version and run a full capsule build:

```yaml
- uses: astrid-runtime/setup-astrid@v2
  with:
    version: "0.9.2"
- run: astrid build
```

A minimal capsule-CI job:

```yaml
name: capsule-ci
on: [push, pull_request]
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astrid-runtime/setup-astrid@v2
      - run: astrid capsule check      # non-zero exit fails the job
```

## Inputs

| Input | Default | Description |
|-------|---------|-------------|
| `version` | `latest` | Astrid version to install (e.g. `0.9.2`), or `latest`. |
| `repository` | `astrid-runtime/astrid` | Owner/repo to install the release from (override for a fork, mirror, or historical Astrid release). |
| `verify` | `sigstore` | `sigstore` (cosign provenance + integrity), `checksum` (SHA256 integrity only, no extra tooling), or `none` (not recommended). |
| `certificate-identity` | *(derived)* | Advanced: override the expected cosign certificate identity. Defaults to the `release.yml` workflow of `repository` at the version tag. |

Historical Astrid releases published before the organization transfer retain the
`unicity-astrid/astrid` Sigstore workflow identity. The default Astrid Runtime
repository automatically retries that historical identity when needed. Forks and an
explicit `certificate-identity` override still require an exact identity match.
| `github-token` | `${{ github.token }}` | Token for the release lookup and asset downloads. |

## Outputs

| Output | Description |
|--------|-------------|
| `version` | The resolved Astrid version that was installed. |
| `bindir` | The directory added to `PATH` containing the Astrid binaries. |

## Verification modes

- **`sigstore`** (default) — installs [cosign](https://github.com/sigstore/cosign) and runs
  `cosign verify-blob` against `SHA256SUMS.txt.sigstore.json`, requiring the signature's
  certificate identity to match the Astrid `release.yml` workflow at the version tag and the
  issuer to be GitHub's OIDC provider. The archive is then checked against the now-trusted
  checksums. This is **authenticity + integrity**: a tampered checksums file or a substituted
  archive both fail.
- **`checksum`** — SHA256 of the archive against `SHA256SUMS.txt` only. No extra tooling
  (uses `sha256sum`/`shasum`, present on every runner). **Integrity** (catches a corrupted or
  on-the-wire-altered download) but not authenticity, so prefer `sigstore` where you can.
- **`none`** — no verification. Emits a warning; not recommended.

## Platform support

macOS and Linux runners, `x86_64` and `aarch64` (Astrid ships those four release targets).
Windows is not supported and fails with a clear error.

## License

Licensed under either of [Apache License, Version 2.0](LICENSE-APACHE) or
[MIT license](LICENSE-MIT) at your option.
