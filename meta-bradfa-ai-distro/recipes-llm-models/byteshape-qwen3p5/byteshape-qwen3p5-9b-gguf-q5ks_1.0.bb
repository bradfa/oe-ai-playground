SUMMARY = "Qwen3.5 9B Q5_K_S GGUF model (byteshape)"
DESCRIPTION = "Qwen3.5 9B parameter model in Q5_K_S GGUF format, quantized by byteshape."
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit huggingface-model
HF_ORG    = "byteshape"
HF_REPO   = "Qwen3.5-9B-GGUF"
HF_FILE   = "Qwen3.5-9B-Q5_K_S-5.10bpw.gguf"
HF_COMMIT = "c0a342e97e5b33fdee725226f7f559426a675968"
SRC_URI[model.sha256sum] = "d9dc093248807262ea8d374b2e0816bf83ab497ec8730c1be20b918b0e2c0ed9"
