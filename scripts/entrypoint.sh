#!/usr/bin/env bash
set -euo pipefail

: "${MODEL_PATH:=/models/Qwen3.6-35B-A3B-UD-Q4_K_M.gguf}"
: "${MMPROJ_PATH:=/models/mmproj-F16.gguf}"
: "${HOST:=0.0.0.0}"
: "${PORT:=8080}"
: "${CTX_SIZE:=262144}"
: "${THREADS:=10}"
: "${THREADS_BATCH:=${THREADS}}"
: "${THREADS_HTTP:=2}"
: "${PARALLEL:=1}"
: "${ENABLE_VISION:=1}"
: "${EXTRA_ARGS:=}"

export OMP_NUM_THREADS="${THREADS}"
export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1
export TOKENIZERS_PARALLELISM=false

args=(
  -m "${MODEL_PATH}"
  --host "${HOST}"
  --port "${PORT}"
  -c "${CTX_SIZE}"
  -t "${THREADS}"
  -tb "${THREADS_BATCH}"
  --threads-http "${THREADS_HTTP}"
  -np "${PARALLEL}"
  -ngl 0
  --metrics
)

if [[ "${ENABLE_VISION}" == "1" && -f "${MMPROJ_PATH}" ]]; then
  args+=(--mmproj "${MMPROJ_PATH}")
fi

echo "Starting llama-server"
echo "MODEL_PATH=${MODEL_PATH}"
echo "MMPROJ_PATH=${MMPROJ_PATH}"
echo "CTX_SIZE=${CTX_SIZE} THREADS=${THREADS} THREADS_BATCH=${THREADS_BATCH} PARALLEL=${PARALLEL}"
echo "EXTRA_ARGS=${EXTRA_ARGS}"

# shellcheck disable=SC2086
exec llama-server "${args[@]}" ${EXTRA_ARGS}
