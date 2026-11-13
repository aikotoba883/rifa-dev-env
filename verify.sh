#!/usr/bin/env bash
# Check that every required tool is on PATH and print its version.
# Exit code: 0 = all present, 1 = something is missing.
set -u

missing=0

echo "MSYSTEM = ${MSYSTEM:-<unset>}"
if [[ "${MSYSTEM:-}" != "UCRT64" ]]; then
  echo "  [WARN] expected MSYSTEM=UCRT64"
  missing=1
fi

check() {
  local name="$1"; shift
  local path
  if path="$(command -v "$name" 2>/dev/null)"; then
    printf "  [ OK ] %-13s %-32s %s\n" "$name" "$path" "$("$@" 2>&1 | head -n 1)"
  else
    printf "  [MISS] %s\n" "$name"
    missing=1
  fi
}

check git          git --version
check vim          vim --version
check ssh          ssh -V
check gcc          gcc --version
check g++          g++ --version
check gdb          gdb --version
check cmake        cmake --version
check ninja        ninja --version
check clang-format clang-format --version
check clang-tidy   clang-tidy --version
check node         node -v
check npm          npm -v
check python       python --version
check psql         psql --version
check pg_ctl       pg_ctl --version
check claude       claude --version

if [[ $missing -eq 0 ]]; then
  echo "All tools present."
else
  echo "Some tools are missing. Re-run ./setup.sh"
fi
exit $missing
