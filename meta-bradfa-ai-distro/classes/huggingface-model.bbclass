# huggingface-model.bbclass
#
# Fetch a single model file from Hugging Face Hub and deploy it for image
# installation.
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
#   HF_INSTALL_DIR - Directory where the model file is installed in the image.
#                    Default: ${datadir}/llama-cpp/models
#                    Override when the model is consumed by a runtime other than
#                    llama.cpp (e.g. HF_INSTALL_DIR = "${datadir}/myruntime/models").
#
# The recipe must also set:
#   SRC_URI[model.sha256sum] - SHA-256 of the downloaded file. On first build,
#                              set it to "" and BitBake will report the correct
#                              value in the fetch error message.
#
# Model files are deployed to DEPLOY_DIR_IMAGE (not installed into packages)
# because IPK and DEB use the ar archive format which caps individual member
# size at ~9.3 GB, making them unsuitable for large quantized models. Running
# large model files through any package manager is also extremely slow and
# wasteful even where the format would allow it.
#
# The packaging tasks (do_package, do_package_write_ipk, etc.) still run but
# produce an empty package with no files. This is necessary because OE's rootfs
# machinery registers all known package_write_ipk tasks as dependencies of
# do_rootfs (to build the opkg repository index), and skipping those tasks via
# noexec breaks the sstate manifest tracking that do_rootfs relies on.
#
# Image recipes reference the model via LLAMA_MODEL_PACKAGE (not IMAGE_INSTALL).
# The llama-cpp-container-image class installs the deployed file directly into
# the rootfs via ROOTFS_POSTPROCESS_COMMAND.
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

# The fetched file lands directly in UNPACKDIR with no subdirectory; override S
# so BitBake does not warn about the default ${UNPACKDIR}/${BP} path not existing.
S = "${UNPACKDIR}"

inherit allarch
inherit deploy

# The package is intentionally empty; the model file goes to DEPLOY_DIR_IMAGE
# via do_deploy. do_package and do_package_write_ipk still run (they are fast
# for an empty package) so that sstate manifests are created for do_rootfs.
FILES:${PN} = ""
ALLOW_EMPTY:${PN} = "1"

do_deploy() {
    install -d ${DEPLOYDIR}${HF_INSTALL_DIR}
    install -m 0644 ${UNPACKDIR}/${HF_FILE_BASENAME} ${DEPLOYDIR}${HF_INSTALL_DIR}/
}
addtask deploy after do_unpack before do_build
