ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE} AS build

ARG APT_MIRROR=
ARG LLAMA_CPP_REPO=https://github.com/ggml-org/llama.cpp.git
ARG LLAMA_CPP_COMMIT=00c461ce1a9deb238eed40a8f869a72729fa3d4f

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN if [[ -n "${APT_MIRROR}" ]]; then \
      sed -i "s|http://archive.ubuntu.com/ubuntu/|${APT_MIRROR}|g; s|http://security.ubuntu.com/ubuntu/|${APT_MIRROR}|g" /etc/apt/sources.list.d/ubuntu.sources; \
    fi && \
    apt-get update && \
    apt-get install --no-install-recommends -y \
      ca-certificates git curl cmake ninja-build build-essential pkg-config \
      libcurl4-openssl-dev libgomp1 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone --filter=blob:none "${LLAMA_CPP_REPO}" llama.cpp && \
    cd llama.cpp && \
    git checkout "${LLAMA_CPP_COMMIT}"

RUN cmake -S /src/llama.cpp -B /build/llama-cpu -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DGGML_NATIVE=ON \
      -DGGML_OPENMP=ON \
      -DGGML_CUDA=OFF \
      -DGGML_HIP=OFF \
      -DGGML_VULKAN=OFF \
      -DLLAMA_CURL=ON \
      -DLLAMA_BUILD_TESTS=OFF \
      -DLLAMA_BUILD_EXAMPLES=ON && \
    cmake --build /build/llama-cpu --target llama-server llama-cli -j"$(nproc)"

FROM ${BASE_IMAGE} AS runtime

ARG APT_MIRROR=
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN if [[ -n "${APT_MIRROR}" ]]; then \
      sed -i "s|http://archive.ubuntu.com/ubuntu/|${APT_MIRROR}|g; s|http://security.ubuntu.com/ubuntu/|${APT_MIRROR}|g" /etc/apt/sources.list.d/ubuntu.sources; \
    fi && \
    apt-get update && \
    apt-get install --no-install-recommends -y \
      ca-certificates curl libgomp1 libcurl4 numactl procps && \
    rm -rf /var/lib/apt/lists/*

COPY --from=build /build/llama-cpu/bin/llama-server /usr/local/bin/llama-server
COPY --from=build /build/llama-cpu/bin/llama-cli /usr/local/bin/llama-cli
COPY scripts/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENV MODEL_PATH=/models/Qwen3.6-35B-A3B-UD-Q4_K_M.gguf \
    MMPROJ_PATH=/models/mmproj-F16.gguf \
    HOST=0.0.0.0 \
    PORT=8080 \
    CTX_SIZE=262144 \
    THREADS=10 \
    THREADS_BATCH=10 \
    THREADS_HTTP=2 \
    PARALLEL=1 \
    ENABLE_VISION=1 \
    EXTRA_ARGS=

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
