SUMMARY = "Minimal container image with busybox shell"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

IMAGE_FSTYPES = "container oci"

inherit image
inherit image-oci
inherit oci-image-adjust

IMAGE_FEATURES = ""
IMAGE_LINGUAS = ""
NO_RECOMMENDATIONS = "1"

IMAGE_INSTALL = " \
    base-files \
    base-passwd \
    busybox \
    catatonit \
    netbase \
"

# catatonit as PID 1 init shim; -- separates catatonit flags from the supervised program
OCI_IMAGE_ENTRYPOINT = "/usr/bin/catatonit --"
OCI_IMAGE_CMD = "/bin/sh"

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
