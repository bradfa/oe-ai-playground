# Sets org.opencontainers.image.ref.name in the OCI index.json to
# IMAGE_BASENAME:OCI_IMAGE_TAG so that podman load imports the image
# with a recognisable name rather than the default "localhost/latest".
#
# jq-native is already a do_image_oci dependency via image-oci.bbclass.

do_set_oci_ref_name() {
    local image_name="${IMAGE_NAME}${IMAGE_NAME_SUFFIX}-oci"
    local ref_name="${IMAGE_BASENAME}:${OCI_IMAGE_TAG}"
    local oci_dir="${IMGDEPLOYDIR}/$image_name"
    local index="$oci_dir/index.json"
    local tar_file="${IMGDEPLOYDIR}/$image_name.tar"

    if [ ! -f "$index" ]; then
        bbwarn "oci-image-name: index.json not found at $index, skipping"
        return
    fi

    bbnote "oci-image-name: Setting ref name to $ref_name"
    jq --arg ref "$ref_name" \
        '.manifests[].annotations["org.opencontainers.image.ref.name"] = $ref' \
        "$index" > "$index.new" && mv "$index.new" "$index"

    if [ -f "$tar_file" ]; then
        bbnote "oci-image-name: Rebuilding OCI tar"
        (cd "$oci_dir" && tar -cf "$tar_file" ".")
    fi
}

do_image_oci[postfuncs] += "do_set_oci_ref_name"
