SUMMARY = "Qwen3.5-0.8B BF16 GGUF model (Unsloth)"
DESCRIPTION = "Qwen3.5 0.8B parameter model in BF16 GGUF format, converted by Unsloth."
HOMEPAGE = "https://huggingface.co/unsloth/Qwen3.5-0.8B-GGUF"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

SRC_URI = "https://huggingface.co/unsloth/Qwen3.5-0.8B-GGUF/resolve/7fc504f0407a77be199ef88330e469e2918fa786/Qwen3.5-0.8B-BF16.gguf;name=model"
SRC_URI[model.sha256sum] = "cedf89af31c9041b601fa58303285bc46d99c51baee1b13f5e919626ca526ee5"

inherit allarch

do_install() {
    install -d ${D}${datadir}/llama-cpp/models
    install -m 0644 ${UNPACKDIR}/Qwen3.5-0.8B-BF16.gguf ${D}${datadir}/llama-cpp/models/
}

FILES:${PN} = "${datadir}/llama-cpp/models"
