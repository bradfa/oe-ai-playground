SUMMARY = "Qwen3.6 35B-A3B Q4_K_S GGUF model (byteshape)"
DESCRIPTION = "Qwen3.6 35B-A3B parameter model in Q4_K_S GGUF format, quantized by byteshape."
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit huggingface-model

HF_ORG    = "byteshape"
HF_REPO   = "Qwen3.6-35B-A3B-GGUF"
HF_FILE   = "Qwen3.6-35B-A3B-Q4_K_S-4.22bpw.gguf"
HF_COMMIT = "57f6dec8727b4c3f5498ff2564a0333ac1f6624a"
SRC_URI[model.sha256sum] = "9eee78b648a2acd0810d822654dc1ed9878dd8cd257e7db2bbb059de197b1098"
