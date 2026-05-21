SUMMARY = "Container image running llama-server with Qwen3.5 9B Q5_K_S model for LLM inference"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

inherit llama-cpp-container-image

# llama-server listens on port 8080 by default. To run the container and expose
# the API on the host, run directly from the OCI layout in the deploy directory:
#
#   podman run --rm -p 8080:8080 \
#     oci:/path/to/build/tmp/deploy/images/qemux86-64/bradfa-container-llama-cpp-byteshape-qwen3p5-9b-q5ks-image-latest-oci:latest
#
# The OpenAI-compatible API is then reachable at http://localhost:8080/v1

LLAMA_MODEL_PACKAGE = "byteshape-qwen3p5-9b-gguf-q5ks"

LLAMA_MODEL_FILE = "Qwen3.5-9B-Q5_K_S-5.10bpw.gguf"
LLAMA_CTX_SIZE = "262144"
LLAMA_REASONING_BUDGET = "9000"
