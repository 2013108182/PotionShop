#!/usr/bin/env bash
# Cloud-only verification; never deploys or publishes.
set -euo pipefail
repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
flutter_bin="${FLUTTER_BIN:-/workspace/tools/flutter/bin/flutter}"
log_dir="${QA_LOG_DIR:-$repo_dir/docs/development-v2/evidence/resumed}"
mkdir -p "$log_dir"
if [[ ! -x "$(dirname "$flutter_bin")/cache/dart-sdk/bin/dart" ]]; then
  echo 'Flutter bundled Dart SDK is absent. Supply a supported complete SDK/cache or authorize the official artifact route; no download workaround is attempted.' >&2
  exit 2
fi
cd "$repo_dir/flutter"
"$flutter_bin" --version 2>&1 | tee "$log_dir/version.log"
"$flutter_bin" pub get 2>&1 | tee "$log_dir/pub-get.log"
"$flutter_bin" analyze 2>&1 | tee "$log_dir/analyze.log"
"$flutter_bin" test 2>&1 | tee "$log_dir/full-test.log"
