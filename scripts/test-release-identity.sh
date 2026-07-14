#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

mkdir -p "${tmp}/bin"
cat > "${tmp}/bin/cosign" <<'FAKE_COSIGN'
#!/usr/bin/env bash
set -euo pipefail

identity=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --certificate-identity)
      identity="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

printf '%s\n' "${identity}" >> "${COSIGN_LOG}"
[[ "${identity}" == "${COSIGN_SUCCEEDS_FOR}" ]]
FAKE_COSIGN
chmod +x "${tmp}/bin/cosign"

current="https://github.com/astrid-runtime/astrid/.github/workflows/release.yml@refs/tags/v0.9.4"
legacy="https://github.com/unicity-astrid/astrid/.github/workflows/release.yml@refs/tags/v0.9.4"
fork="https://github.com/example/astrid/.github/workflows/release.yml@refs/tags/v0.9.4"
override="https://github.com/operator/releases/.github/workflows/sign.yml@refs/tags/v0.9.4"

run_success() {
  local name="$1" repository="$2" succeeds_for="$3" identity_override="${4:-}"
  local log="${tmp}/${name}.log"
  PATH="${tmp}/bin:${PATH}" COSIGN_LOG="${log}" COSIGN_SUCCEEDS_FOR="${succeeds_for}" \
    "${repo_root}/scripts/verify-release-identity.sh" \
    "${repository}" "v0.9.4" "${identity_override}"
}

run_failure() {
  local name="$1" repository="$2" identity_override="${3:-}"
  local log="${tmp}/${name}.log"
  if PATH="${tmp}/bin:${PATH}" COSIGN_LOG="${log}" COSIGN_SUCCEEDS_FOR="never" \
    "${repo_root}/scripts/verify-release-identity.sh" \
    "${repository}" "v0.9.4" "${identity_override}"; then
    echo "expected ${name} to fail" >&2
    exit 1
  fi
}

run_success current astrid-runtime/astrid "${current}"
[[ "$(wc -l < "${tmp}/current.log" | tr -d ' ')" == "1" ]]

run_success legacy astrid-runtime/astrid "${legacy}"
[[ "$(sed -n '1p' "${tmp}/legacy.log")" == "${current}" ]]
[[ "$(sed -n '2p' "${tmp}/legacy.log")" == "${legacy}" ]]
[[ "$(wc -l < "${tmp}/legacy.log" | tr -d ' ')" == "2" ]]

run_success fork example/astrid "${fork}"
[[ "$(wc -l < "${tmp}/fork.log" | tr -d ' ')" == "1" ]]

run_success override astrid-runtime/astrid "${override}" "${override}"
[[ "$(wc -l < "${tmp}/override.log" | tr -d ' ')" == "1" ]]

run_failure fork-failure example/astrid
[[ "$(wc -l < "${tmp}/fork-failure.log" | tr -d ' ')" == "1" ]]

run_failure override-failure astrid-runtime/astrid "${override}"
[[ "$(wc -l < "${tmp}/override-failure.log" | tr -d ' ')" == "1" ]]

run_failure canonical-failure astrid-runtime/astrid
[[ "$(wc -l < "${tmp}/canonical-failure.log" | tr -d ' ')" == "2" ]]

echo "release identity policy tests passed"
