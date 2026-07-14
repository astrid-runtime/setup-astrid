#!/usr/bin/env bash

set -euo pipefail

repository="${1:?repository is required}"
tag="${2:?tag is required}"
identity_override="${3:-}"

issuer="https://token.actions.githubusercontent.com"
canonical_repository="astrid-runtime/astrid"
legacy_repository="unicity-astrid/astrid"

verify_identity() {
  local expected="$1"
  echo "setup-astrid: verifying SHA256SUMS.txt provenance via cosign (identity: ${expected})"
  cosign verify-blob \
    --bundle "SHA256SUMS.txt.sigstore.json" \
    --certificate-identity "${expected}" \
    --certificate-oidc-issuer "${issuer}" \
    "SHA256SUMS.txt"
}

if [[ -n "${identity_override}" ]]; then
  verify_identity "${identity_override}"
  exit 0
fi

current_identity="https://github.com/${repository}/.github/workflows/release.yml@refs/tags/${tag}"
if verify_identity "${current_identity}"; then
  exit 0
fi

# Releases made before the organization transfer retain the original GitHub
# OIDC workflow identity. Keep this fallback deliberately narrow: forks and
# mirrors must prove their own identity, and an explicit override must match
# exactly rather than silently widening the trust set.
if [[ "${repository}" != "${canonical_repository}" ]]; then
  exit 1
fi

legacy_identity="https://github.com/${legacy_repository}/.github/workflows/release.yml@refs/tags/${tag}"
echo "setup-astrid: retrying historical Astrid release identity"
verify_identity "${legacy_identity}"
