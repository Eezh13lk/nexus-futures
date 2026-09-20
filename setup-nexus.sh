#!/usr/bin/env bash
set -euo pipefail

# NEXUS Futures 5.0.1 build fix
# The current 5.0 generator has two Java references that use e.rsi/e.atr
# as fields even though they are methods. This wrapper uses the exact
# generator from the current 5.0 commit, patches those two references,
# then runs the generator. The GitHub Actions workflow needs no change.

BASE_URL="https://raw.githubusercontent.com/Eezh13lk/nexus-futures/4fe707b45397465404fcf67170a4355546c90251/setup-nexus.sh"
TMP="/tmp/nexus-base-5.0.sh"

curl -fsSL "$BASE_URL" -o "$TMP"

# Fix Java compilation errors shown in the GitHub Actions log:
#   fmt(e.rsi) -> fmt(e.rsi(14))
#   fmt(e.atr) -> fmt(e.atr(14))
sed -i \
  -e 's/fmt(e\.rsi)/fmt(e.rsi(14))/g' \
  -e 's/fmt(e\.atr)/fmt(e.atr(14))/g' \
  "$TMP"

bash "$TMP"

echo "NEXUS Futures 5.0.1 project generated successfully."
