#!/usr/bin/env bash
set -euo pipefail

IMAGE="${IMAGE:-qwen36-llamacpp-cpu:00c461c}"
BASE_IMAGE="${BASE_IMAGE:-ubuntu:24.04}"
APT_MIRROR="${APT_MIRROR:-}"
LLAMA_CPP_REPO="${LLAMA_CPP_REPO:-https://github.com/ggml-org/llama.cpp.git}"
LLAMA_CPP_COMMIT="${LLAMA_CPP_COMMIT:-00c461ce1a9deb238eed40a8f869a72729fa3d4f}"
LLAMA_BUILD_UI="${LLAMA_BUILD_UI:-ON}"

usage() {
  cat <<'USAGE'
Usage: ./scripts/build.sh [--enable-ui|--disable-ui]

Environment variables:
  IMAGE              Docker image tag. Default: qwen36-llamacpp-cpu:00c461c
  BASE_IMAGE         Base image. Default: ubuntu:24.04
  APT_MIRROR         Optional apt mirror URL.
  LLAMA_CPP_REPO     llama.cpp git repo URL.
  LLAMA_CPP_COMMIT   llama.cpp commit to checkout.
  LLAMA_BUILD_UI     ON or OFF. Default: ON.

Use --disable-ui for offline or restricted networks because llama.cpp may
otherwise try npm/HF Bucket asset downloads during Docker builds.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --enable-ui)
      LLAMA_BUILD_UI=ON
      shift
      ;;
    --disable-ui)
      LLAMA_BUILD_UI=OFF
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

docker build \
  --build-arg BASE_IMAGE="${BASE_IMAGE}" \
  --build-arg APT_MIRROR="${APT_MIRROR}" \
  --build-arg LLAMA_CPP_REPO="${LLAMA_CPP_REPO}" \
  --build-arg LLAMA_CPP_COMMIT="${LLAMA_CPP_COMMIT}" \
  --build-arg LLAMA_BUILD_UI="${LLAMA_BUILD_UI}" \
  -t "${IMAGE}" \
  .
