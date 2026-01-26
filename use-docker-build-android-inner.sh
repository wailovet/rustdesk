#!/bin/bash
set -e

# Check if generated_bridge.dart exists, if not, regenerate it
if [ ! -f "flutter/lib/generated_bridge.dart" ]; then
    echo "Regenerating flutter_rust_bridge code..."
    flutter_rust_bridge_codegen --rust-input ./src/flutter_ffi.rs --dart-output ./flutter/lib/generated_bridge.dart --c-output ./flutter/macos/Runner/bridge_generated.h
    # Copy bridge_generated.h to iOS directory if needed (based on typical setup, but focusing on Android here)
    # The build.py usually handles this, but since we are running a custom flow:
    # cp flutter/macos/Runner/bridge_generated.h flutter/ios/Runner/bridge_generated.h
fi

# Build Android APK
cd flutter
flutter build apk --release --target-platform android-arm64 --split-per-abi