#!/usr/bin/env bash
set -euo pipefail

IMAGE="${IMAGE:-qwen36-llamacpp-cpu:00c461c}"
BASE_IMAGE="${BASE_IMAGE:-ubuntu:24.04}"
APT_MIRROR="${APT_MIRROR:-}"
LLAMA_CPP_REPO="${LLAMA_CPP_REPO:-https://github.com/ggml-org/llama.cpp.git}"
LLAMA_CPP_COMMIT="${LLAMA_CPP_COMMIT:-00c461ce1a9deb238eed40a8f869a72729fa3d4f}"

docker build \
  --build-arg BASE_IMAGE="${BASE_IMAGE}" \
  --build-arg APT_MIRROR="${APT_MIRROR}" \
  --build-arg LLAMA_CPP_REPO="${LLAMA_CPP_REPO}" \
  --build-arg LLAMA_CPP_COMMIT="${LLAMA_CPP_COMMIT}" \
  -t "${IMAGE}" \
  .
