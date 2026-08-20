#!/usr/bin/env bash
set -euo pipefail
required=(python3 terraform kubectl kubeconform)
optional=(ruff pytest checkov trivy gitleaks docker)
missing=0
for tool in "${required[@]}"; do
  if command -v "${tool}" >/dev/null 2>&1; then
    printf 'required  %-16s found\n' "${tool}"
  else
    printf 'required  %-16s MISSING\n' "${tool}"
    missing=1
  fi
done

for tool in "${optional[@]}"; do
  if command -v "${tool}" >/dev/null 2>&1; then
    printf 'optional  %-16s found\n' "${tool}"
  else
    printf 'optional  %-16s missing\n' "${tool}"
  fi
done

exit "${missing}"
