#!/bin/bash
set -e

# Setup Flutter Android signing
ANDROID_DIR="flutter/android"
KEYSTORE_PATH="$ANDROID_DIR/upload-keystore.jks"
KEY_PROPS_PATH="$ANDROID_DIR/key.properties"

if [ ! -f "$KEYSTORE_PATH" ]; then
    echo "Generating development keystore..."
    keytool -genkey -v -keystore "$KEYSTORE_PATH" \
        -storepass android -alias android -keypass android \
        -keyalg RSA -keysize 2048 -validity 10000 \
        -dname "CN=Android Debug,O=Android,C=US"
fi

# Always ensure key.properties is correct when we have our keystore
# We use ../upload-keystore.jks because build.gradle resolves relative to app/ directory
if [ -f "$KEYSTORE_PATH" ]; then
    echo "Updating key.properties..."
    echo "storePassword=android" > "$KEY_PROPS_PATH"
    echo "keyPassword=android" >> "$KEY_PROPS_PATH"
    echo "keyAlias=android" >> "$KEY_PROPS_PATH"
    echo "storeFile=../upload-keystore.jks" >> "$KEY_PROPS_PATH"
fi

# Check if generated_bridge.dart exists, if not, regenerate it
if [ ! -f "flutter/lib/generated_bridge.dart" ]; then
    echo "Regenerating flutter_rust_bridge code..."
    flutter_rust_bridge_codegen --rust-input ./src/flutter_ffi.rs --dart-output ./flutter/lib/generated_bridge.dart --c-output ./flutter/macos/Runner/bridge_generated.h
fi

# Build Android APK
echo "Building Flutter APK..."
cd flutter
flutter build apk --release --target-platform android-arm64 --split-per-abi