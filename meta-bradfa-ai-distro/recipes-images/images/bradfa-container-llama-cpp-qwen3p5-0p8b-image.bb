SUMMARY = "Container image running llama-server with Qwen3.5-0.8B model for LLM inference"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

inherit llama-cpp-container-image

# llama-server listens on port 8080 by default. To run the container and expose
# the API on the host:
#
#   podman run --rm -p 8080:8080 <image>
#   docker run --rm -p 8080:8080 <image>
#
# The OpenAI-compatible API is then reachable at http://localhost:8080/v1

IMAGE_INSTALL:append = " unsloth-qwen3p5-0p8b-gguf-bf16"

LLAMA_MODEL_FILE = "Qwen3.5-0.8B-BF16.gguf"
