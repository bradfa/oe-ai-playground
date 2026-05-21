# huggingface-model.bbclass
#
# Fetch a single model file from Hugging Face Hub and install it.
#
# Required variables:
#   HF_ORG    - Hugging Face organization or user name (e.g. "unsloth")
#   HF_REPO   - Repository name (e.g. "Qwen3.5-0.8B-GGUF")
#   HF_FILE   - File path within the repository. Preserves subdirectory paths
#               (e.g. "Qwen3.5-0.8B-BF16.gguf" or "subdir/file.gguf").
#               Use scripts/hf-lookup.sh to find the correct value.
#   HF_COMMIT - Full 40-character commit hash pinning the fetch to an immutable
#               revision. Use scripts/hf-lookup.sh to find this value.
#               A branch name (e.g. "main") also works but is not reproducible.
#
# Optional variables:
#   HF_INSTALL_DIR - Directory where the model file is installed.
#                    Default: ${datadir}/llama-cpp/models
#                    Override when the model is consumed by a runtime other than
#                    llama.cpp (e.g. HF_INSTALL_DIR = "${datadir}/myruntime/models").
#
# The recipe must also set:
#   SRC_URI[model.sha256sum] - SHA-256 of the downloaded file. On first build,
#                              set it to "" and BitBake will report the correct
#                              value in the fetch error message.
#
# Minimal recipe example:
#
#   SUMMARY = "Qwen3.5 0.8B BF16 GGUF model (Unsloth)"
#   LICENSE = "Apache-2.0"
#   LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"
#
#   inherit huggingface-model
#
#   HF_ORG    = "unsloth"
#   HF_REPO   = "Qwen3.5-0.8B-GGUF"
#   HF_FILE   = "Qwen3.5-0.8B-BF16.gguf"
#   HF_COMMIT = "7fc504f0407a77be199ef88330e469e2918fa786"
#   SRC_URI[model.sha256sum] = "cedf89af31c9041b601fa58303285bc46d99c51baee1b13f5e919626ca526ee5"

HOMEPAGE ?= "https://huggingface.co/${HF_ORG}/${HF_REPO}"

HF_INSTALL_DIR ?= "${datadir}/llama-cpp/models"

HF_FILE_BASENAME = "${@os.path.basename(d.getVar('HF_FILE'))}"

SRC_URI = "https://huggingface.co/${HF_ORG}/${HF_REPO}/resolve/${HF_COMMIT}/${HF_FILE};name=model"

inherit allarch

do_install() {
    install -d ${D}${HF_INSTALL_DIR}
    install -m 0644 ${UNPACKDIR}/${HF_FILE_BASENAME} ${D}${HF_INSTALL_DIR}/
}

FILES:${PN} = "${HF_INSTALL_DIR}"
