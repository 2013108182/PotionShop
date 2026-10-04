#!/usr/bin/env bash
# Cloud-only verification. This does not deploy or publish anything.
set -euo pipefail
repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
flutter_bin="${FLUTTER_BIN:-/workspace/tools/flutter/bin/flutter}"
log_dir="${QA_LOG_DIR:-$repo_dir/docs/playtest-1598880/evidence/resumed}"
mkdir -p "$log_dir"
cd "$repo_dir/flutter"
"$flutter_bin" --version 2>&1 | tee "$log_dir/version.log"
"$flutter_bin" pub get 2>&1 | tee "$log_dir/pub-get.log"
"$flutter_bin" test test/playtest_regression_test.dart test/shop_test.dart 2>&1 | tee "$log_dir/regression-test.log"
"$flutter_bin" test 2>&1 | tee "$log_dir/full-test.log"
"$flutter_bin" analyze 2>&1 | tee "$log_dir/analyze.log"
