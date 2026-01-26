#!/bin/bash
set -e

# 检查是否提供了必要的参数或环境变量，如果有则设置默认值
IMAGE_NAME="rustdesk-android-cache:latest"
CONTAINER_WORK_DIR="/workspace"

# 尝试加载 .env 文件
if [ -f .env ]; then
  echo "Loading variables from .env file..."
  export $(grep -v '^#' .env | xargs)
fi

KEY_ALIAS="${KEY_ALIAS:-android}"
KEY_PASSWORD="${KEY_PASSWORD:-android}"
STORE_PASSWORD="${STORE_PASSWORD:-android}"

# 获取当前脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo "============================================"
echo "Build Configuration:"
echo "Image Name: ${IMAGE_NAME}"
echo "Key Alias: ${KEY_ALIAS}"
echo "Proxy Settings:"
echo "  http_proxy: ${http_proxy}"
echo "  https_proxy: ${https_proxy}"
echo "  no_proxy: ${no_proxy}"
echo "============================================"

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
    cd flutter && \
    flutter build apk --release --target-platform android-arm64 --split-per-abi
  "

echo "Build complete. Check flutter/build/app/outputs/flutter-apk/ for APKs."