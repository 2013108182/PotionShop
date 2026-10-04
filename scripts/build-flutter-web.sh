#!/usr/bin/env bash
set -euo pipefail

# Use the same SDK as the verified desktop development build.
readonly FLUTTER_VERSION=3.47.6
readonly FLUTTER_REVISION=5fc346839b5d0eef006ed8404392afb4dfae428d
BUILD_FLUTTER_SDK="$(mktemp -d /tmp/potionshop-flutter.XXXXXX)"
git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$BUILD_FLUTTER_SDK"
test "$(git -C "$BUILD_FLUTTER_SDK" rev-parse HEAD)" = "$FLUTTER_REVISION"
export PATH="$BUILD_FLUTTER_SDK/bin:$PATH"
export CI=true
flutter config --no-analytics
cd flutter
flutter pub get --enforce-lockfile
flutter build web --release --no-web-resources-cdn
