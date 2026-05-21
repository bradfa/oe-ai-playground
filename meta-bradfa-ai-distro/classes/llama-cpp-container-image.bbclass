# llama-cpp-container-image.bbclass
#
# Base class for OCI container images that run llama-server from llama-cpp.
# Provides all image boilerplate so a recipe only needs to specify the model.
#
# Required variables:
#   LLAMA_MODEL_FILE - Filename of the model as installed on the target,
#                      e.g. "Qwen3.5-0.8B-BF16.gguf".
#                      Must match HF_FILE_BASENAME from the model recipe.
#
# Optional variables:
#   LLAMA_MODEL_DIR        - Directory where the model file is installed.
#                            Default: ${datadir}/llama-cpp/models
#                            Override only when using a non-default HF_INSTALL_DIR
#                            in the model recipe.
#   LLAMA_HOST             - llama-server --host binding. Default: 0.0.0.0
#   LLAMA_CTX_SIZE         - Context window size. Default: 16384
#   LLAMA_TEMP             - Sampling temperature. Default: 1.0
#   LLAMA_TOP_P            - Top-p sampling. Default: 0.95
#   LLAMA_TOP_K            - Top-k sampling. Default: 20
#   LLAMA_MIN_P            - Min-p threshold. Default: 0.00
#   LLAMA_REASONING_BUDGET - Thinking budget passed to --reasoning-budget.
#                            0 disables thinking (non-reasoning mode).
#                            -1 enables thinking with no token cap.
#                            Default: 0
#   LLAMA_EXTRA_ARGS       - Extra arguments appended verbatim to OCI_IMAGE_CMD.
#                            Default: (empty)
#
# The recipe must also set:
#   LICENSE, LIC_FILES_CHKSUM
#   IMAGE_INSTALL:append  - add the model package, e.g.:
#                           IMAGE_INSTALL:append = " unsloth-qwen3p5-0p8b-gguf-bf16"
#
# Running the image:
#   The build produces an OCI image layout directory in deploy/images/. Use the
#   oci: transport to run it directly without importing into the local store:
#
#   podman run --rm -p 8080:8080 \
#     oci:/path/to/build/tmp/deploy/images/<machine>/<image-name>-latest-oci:latest
#
# Minimal recipe example:
#
#   SUMMARY = "Container image running llama-server with Qwen3.5-0.8B"
#   LICENSE = "MIT"
#   LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"
#
#   inherit llama-cpp-container-image
#
#   IMAGE_INSTALL:append = " unsloth-qwen3p5-0p8b-gguf-bf16"
#
#   LLAMA_MODEL_FILE = "Qwen3.5-0.8B-BF16.gguf"
#
# Image recipe naming convention:
#   <namespace>-container-llama-cpp-<model-id>-image.bb
#   where <model-id> follows <org>-<model>-<size>-<quant> (dots→p, lowercase,
#   underscores dropped), e.g. unsloth-qwen3p5-0p8b-bf16.

IMAGE_FSTYPES = "container oci"

inherit image
inherit image-oci
inherit oci-image-adjust

IMAGE_FEATURES = ""
IMAGE_LINGUAS = ""
NO_RECOMMENDATIONS = "1"
IMAGE_CONTAINER_NO_DUMMY = "1"

# catatonit as PID 1 init shim; -- separates catatonit flags from the supervised program
OCI_IMAGE_ENTRYPOINT = "/usr/bin/catatonit --"

IMAGE_INSTALL = " \
    base-files \
    base-passwd \
    busybox \
    catatonit \
    llama-cpp \
    netbase \
"

LLAMA_MODEL_DIR ?= "${datadir}/llama-cpp/models"
LLAMA_HOST ?= "0.0.0.0"
LLAMA_CTX_SIZE ?= "16384"
LLAMA_TEMP ?= "1.0"
LLAMA_TOP_P ?= "0.95"
LLAMA_TOP_K ?= "20"
LLAMA_MIN_P ?= "0.00"
LLAMA_REASONING_BUDGET ?= "0"
LLAMA_EXTRA_ARGS ?= ""

LLAMA_MODEL_PATH = "${LLAMA_MODEL_DIR}/${LLAMA_MODEL_FILE}"

OCI_IMAGE_CMD = "/usr/bin/llama-server \
    --host ${LLAMA_HOST} \
    --model ${LLAMA_MODEL_PATH} \
    --ctx-size ${LLAMA_CTX_SIZE} \
    --temp ${LLAMA_TEMP} \
    --top-p ${LLAMA_TOP_P} \
    --top-k ${LLAMA_TOP_K} \
    --min-p ${LLAMA_MIN_P} \
    --reasoning-budget ${LLAMA_REASONING_BUDGET} \
    ${LLAMA_EXTRA_ARGS}"

# /var/volatile directories are not created without postinstall scripts running
ROOTFS_POSTPROCESS_COMMAND += "rootfs_fixup_var_volatile ; "
ROOTFS_POSTPROCESS_COMMAND:remove = "empty_var_volatile"

rootfs_fixup_var_volatile () {
    install -m 1777 -d ${IMAGE_ROOTFS}/${localstatedir}/volatile/tmp
    install -m 755 -d ${IMAGE_ROOTFS}/${localstatedir}/volatile/log
}
