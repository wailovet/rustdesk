#!/bin/bash
set -e

# 检查是否提供了必要的参数或环境变量，如果有则设置默认值
IMAGE_NAME="rustdesk-android-cache:latest"
CONTAINER_WORK_DIR="/workspace"
KEY_ALIAS="${KEY_ALIAS:-android}"
KEY_PASSWORD="${KEY_PASSWORD:-android}"
STORE_PASSWORD="${STORE_PASSWORD:-android}"

# 获取当前脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# 构建镜像（如果不存在或强制构建）
echo "Building Docker image..."
docker build \
  --build-arg http_proxy="${http_proxy}" \
  --build-arg https_proxy="${https_proxy}" \
  --build-arg no_proxy="${no_proxy}" \
  --build-arg KEY_ALIAS="${KEY_ALIAS}" \
  --build-arg KEY_PASSWORD="${KEY_PASSWORD}" \
  --build-arg STORE_PASSWORD="${STORE_PASSWORD}" \
  -f "${SCRIPT_DIR}/Dockerfile.build-rustdesk-android" \
  -t "${IMAGE_NAME}" .

# 运行容器进行编译
echo "Running build in container..."
docker run --rm -it \
  -v "${SCRIPT_DIR}:${CONTAINER_WORK_DIR}" \
  -e http_proxy="${http_proxy}" \
  -e https_proxy="${https_proxy}" \
  -e no_proxy="${no_proxy}" \
  -e KEY_ALIAS="${KEY_ALIAS}" \
  -e KEY_PASSWORD="${KEY_PASSWORD}" \
  -e STORE_PASSWORD="${STORE_PASSWORD}" \
  "${IMAGE_NAME}" \
  /bin/bash -c "
    git config --global --add safe.directory '*' && \
    git submodule update --init --recursive && \
    ./flutter/ndk_arm64.sh && \
    sed -i 's/org.gradle.jvmargs=-Xmx1024M/org.gradle.jvmargs=-Xmx2g/g' ./flutter/android/gradle.properties && \
    keytool -genkey -v -keystore ./flutter/android/app/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias \$KEY_ALIAS -storepass \$STORE_PASSWORD -keypass \$KEY_PASSWORD -dname 'CN=Android Debug,O=Android,C=US' && \
    echo 'storeFile=key.jks' > ./flutter/android/key.properties && \
    echo 'storePassword='\$STORE_PASSWORD >> ./flutter/android/key.properties && \
    echo 'keyAlias='\$KEY_ALIAS >> ./flutter/android/key.properties && \
    echo 'keyPassword='\$KEY_PASSWORD >> ./flutter/android/key.properties && \
    mkdir -p ./flutter/android/app/src/main/jniLibs/arm64-v8a && \
    cp \${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so ./flutter/android/app/src/main/jniLibs/arm64-v8a/ && \
    cp ./target/aarch64-linux-android/release/liblibrustdesk.so ./flutter/android/app/src/main/jniLibs/arm64-v8a/librustdesk.so && \
    cd flutter && \
    flutter build apk --release --target-platform android-arm64 --split-per-abi
  "

echo "Build complete. Check flutter/build/app/outputs/flutter-apk/ for APKs."