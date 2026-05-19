#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-8080}"

curl -s "http://127.0.0.1:${PORT}/v1/chat/completions" \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer sk-local' \
  -d '{
    "model": "local",
    "temperature": 0,
    "max_tokens": 96,
    "messages": [
      {"role": "user", "content": "用一句中文说明 CPU 推理为什么要绑核。"}
    ]
  }' | python3 -m json.tool
