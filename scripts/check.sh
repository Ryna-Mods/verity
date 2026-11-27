#!/usr/bin/env bash
# Every check CI runs, from the repository root: needs lua5.1 (or lua), luacheck and node.
set -euo pipefail
cd "$(dirname "$0")/.."
LUA="${LUA:-$(command -v lua5.1 || command -v lua)}"
node scripts/core.mjs
node scripts/version.mjs
luacheck Ryna_Verity test --no-color
if command -v luac5.1 >/dev/null; then
  for f in Ryna_Verity/*.lua Ryna_Verity/Locales/*.lua; do luac5.1 -p "$f"; done
fi
node tools/strings.mjs
failed=0
for t in test/*_test.lua; do
  "$LUA" "$t" || failed=$((failed + 1))
done
if [ "$failed" -ne 0 ]; then echo "$failed test file(s) failed"; exit 1; fi
echo "all green"
