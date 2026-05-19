#!/usr/bin/env bash
set -euo pipefail

IMAGE="${IMAGE:-qwen36-llamacpp-cpu:00c461c}"
NAME="${NAME:-qwen36-llama}"
MODEL_DIR="${MODEL_DIR:-$(pwd)/models}"
PORT="${PORT:-8080}"
THREADS="${THREADS:-10}"
PARALLEL="${PARALLEL:-1}"
CTX_SIZE="${CTX_SIZE:-262144}"
ENABLE_VISION="${ENABLE_VISION:-1}"

docker rm -f "${NAME}" >/dev/null 2>&1 || true

docker run -d \
  --name "${NAME}" \
  --restart unless-stopped \
  --cpuset-cpus "${CPUSET_CPUS:-0-9}" \
  --ulimit memlock=-1:-1 \
  -p "${PORT}:8080" \
  -v "${MODEL_DIR}:/models:ro" \
  -e MODEL_PATH=/models/Qwen3.6-35B-A3B-UD-Q4_K_M.gguf \
  -e MMPROJ_PATH=/models/mmproj-F16.gguf \
  -e CTX_SIZE="${CTX_SIZE}" \
  -e THREADS="${THREADS}" \
  -e THREADS_BATCH="${THREADS}" \
  -e THREADS_HTTP=2 \
  -e PARALLEL="${PARALLEL}" \
  -e ENABLE_VISION="${ENABLE_VISION}" \
  -e EXTRA_ARGS="${EXTRA_ARGS:-}" \
  "${IMAGE}"

echo "Started ${NAME}. Logs:"
echo "  docker logs -f ${NAME}"
echo "Health:"
echo "  curl http://127.0.0.1:${PORT}/health"
