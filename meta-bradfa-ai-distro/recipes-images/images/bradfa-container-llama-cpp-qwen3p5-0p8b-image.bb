SUMMARY = "Container image running llama-server with Qwen3.5-0.8B model for LLM inference"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

IMAGE_FSTYPES = "container oci"

inherit image
inherit image-oci
inherit oci-image-adjust

# llama-server listens on port 8080 by default. To run the container and expose
# the API on the host:
#
#   podman run --rm -p 8080:8080 <image>
#   docker run --rm -p 8080:8080 <image>
#
# The OpenAI-compatible API is then reachable at http://localhost:8080/v1

IMAGE_FEATURES = ""
IMAGE_LINGUAS = ""
NO_RECOMMENDATIONS = "1"

IMAGE_INSTALL = " \
    base-files \
    base-passwd \
    busybox \
    catatonit \
    llama-cpp \
    netbase \
    unsloth-qwen3p5-0p8b-gguf-bf16 \
"

# catatonit as PID 1 init shim; -- separates catatonit flags from the supervised program
OCI_IMAGE_ENTRYPOINT = "/usr/bin/catatonit --"

# Launch llama-server using qwen3.5 model with 16k context and no thinking
OCI_IMAGE_CMD = "/usr/bin/llama-server \
    --host 0.0.0.0 \
    --model /usr/share/llama-cpp/models/Qwen3.5-0.8B-BF16.gguf \
    --ctx-size 16384 \
    --temp 1.0 \
    --top-p 0.95 \
    --top-k 20 \
    --min-p 0.00 \
    --reasoning-budget 0 \
"

# Allow build with or without a specific kernel
IMAGE_CONTAINER_NO_DUMMY = "1"

# /var/volatile directories are not created without postinstall scripts running,
# copied from container-base.bb recipe
ROOTFS_POSTPROCESS_COMMAND += "rootfs_fixup_var_volatile ; "
ROOTFS_POSTPROCESS_COMMAND:remove = "empty_var_volatile"

rootfs_fixup_var_volatile () {
    install -m 1777 -d ${IMAGE_ROOTFS}/${localstatedir}/volatile/tmp
    install -m 755 -d ${IMAGE_ROOTFS}/${localstatedir}/volatile/log
}
