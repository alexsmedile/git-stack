#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== Running Git Operator Automated Test Suite ==="
node --test "$DIR/tests/test-suite.mjs"
echo "=== Running Hard/Adversarial Suite ==="
node --test "$DIR/tests/hard-suite.mjs"
