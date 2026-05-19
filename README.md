# Qwen3.6 35B A3B GGUF CPU Docker Deployment

This package reproduces the tested path:

- runtime: llama.cpp CPU-only server
- llama.cpp commit: `00c461ce1a9deb238eed40a8f869a72729fa3d4f`
- model: `Qwen3.6-35B-A3B-UD-Q4_K_M.gguf`
- optional vision: `mmproj-F16.gguf`
- API: OpenAI-compatible `/v1/chat/completions`

The tested machine used `-ngl 0`, `-t 10`, `-tb 10`, and no MTP. MTP was slower on CPU in the benchmark, so it is intentionally not enabled here.

## 1. Put Model Files In Place

Create a model directory on the IDC host:

```bash
mkdir -p /data/models/qwen36-mtp-gguf
```

Place these files in it:

```text
/data/models/qwen36-mtp-gguf/Qwen3.6-35B-A3B-UD-Q4_K_M.gguf
/data/models/qwen36-mtp-gguf/mmproj-F16.gguf
```

Expected sizes from the test machine:

```text
Qwen3.6-35B-A3B-UD-Q4_K_M.gguf  ~22G
mmproj-F16.gguf                 ~858M
```

## 2. Build Image

Default build:

```bash
cd qwen36-llamacpp-docker
IMAGE=qwen36-llamacpp-cpu:00c461c ./scripts/build.sh
```

If Docker Hub or GitHub access is slow, use mirrors:

```bash
BASE_IMAGE=docker.1ms.run/library/ubuntu:24.04 \
APT_MIRROR=http://mirrors.aliyun.com/ubuntu/ \
LLAMA_CPP_REPO=https://gh-proxy.com/https://github.com/ggml-org/llama.cpp.git \
IMAGE=qwen36-llamacpp-cpu:00c461c \
./scripts/build.sh
```

If the mirror path for Ubuntu differs in your IDC, override `BASE_IMAGE` accordingly.

## 3. Run Text + Vision Server

Conservative single-request setup:

```bash
MODEL_DIR=/data/models/qwen36-mtp-gguf \
THREADS=10 \
PARALLEL=1 \
CTX_SIZE=262144 \
PORT=8080 \
./scripts/run.sh
```

Fixed multi-slot serving setup for concurrent traffic:

```bash
MODEL_DIR=/data/models/qwen36-mtp-gguf \
THREADS=10 \
PARALLEL=4 \
CTX_SIZE=32768 \
PORT=8080 \
./scripts/run.sh
```

Notes:

- `PARALLEL` maps to llama.cpp `-np`.
- `THREADS` maps to `-t` and `-tb`.
- `CPUSET_CPUS` defaults to `0-9`.
- `ENABLE_VISION=1` loads `mmproj-F16.gguf`.
- `EXTRA_ARGS` can pass extra llama-server flags.

## 4. Verify

Health:

```bash
curl http://127.0.0.1:8080/health
```

Text smoke test:

```bash
./scripts/smoke_text.sh
```

Vision smoke test:

```bash
python3 ./scripts/smoke_vision.py
```

Expected vision answer should identify a red background and blue square.

## 5. Current Benchmark Reference

On the AutoDL 6459C test machine:

Text/long prompt, non-MTP:

```text
raw short decode: 18.09 tok/s
raw long prefill: 76.82 tok/s
raw long decode: 14.84 tok/s
pi-agent turn2 cacheRead: 11064
```

Vision smoke:

```text
image processed in ~247 ms
decode: ~17.8 tok/s
```

Vision concurrency with fixed `-np 4`, `-c 32768`, 4 requests, `max_tokens=96`:

```text
client concurrency 1: total 16.30 output tok/s, avg single-request decode 19.34 tok/s
client concurrency 2: total 19.88 output tok/s, avg single-request decode 11.86 tok/s
client concurrency 4: total 21.07 output tok/s, avg single-request decode 11.89 tok/s
```

## 6. Operational Defaults

For IDC first trial, start with:

```bash
THREADS=10
PARALLEL=1
CTX_SIZE=262144
ENABLE_VISION=1
```

Then test:

```bash
PARALLEL=4
CTX_SIZE=32768
```

Use `PARALLEL=4` only if you need concurrent serving and can tolerate higher per-request latency.

## 7. Logs

```bash
docker logs -f qwen36-llama
```

The startup log should include:

```text
no usable GPU found
n_threads = 10
loaded multimodal model, '.../mmproj-F16.gguf'
server is listening on http://0.0.0.0:8080
```
