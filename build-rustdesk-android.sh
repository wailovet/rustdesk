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
