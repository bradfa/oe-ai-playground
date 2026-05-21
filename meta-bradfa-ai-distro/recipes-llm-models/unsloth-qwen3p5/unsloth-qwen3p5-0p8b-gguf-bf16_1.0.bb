SUMMARY = "Qwen3.5 0.8B BF16 GGUF model (Unsloth)"
DESCRIPTION = "Qwen3.5 0.8B parameter model in BF16 GGUF format, converted by Unsloth."
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit huggingface-model

HF_ORG    = "unsloth"
HF_REPO   = "Qwen3.5-0.8B-GGUF"
HF_FILE   = "Qwen3.5-0.8B-BF16.gguf"
HF_COMMIT = "7fc504f0407a77be199ef88330e469e2918fa786"
SRC_URI[model.sha256sum] = "cedf89af31c9041b601fa58303285bc46d99c51baee1b13f5e919626ca526ee5"
