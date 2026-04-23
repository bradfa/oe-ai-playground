# Set org.opencontainers.image.ref.name in the OCI index.json to
# IMAGE_BASENAME:OCI_IMAGE_TAG so that podman load imports the image with a
# recognisable name rather than the default "localhost/latest" and also sets
# the image created timestamp to the image build time so it shows up sensibly
# in `podman image ls`.
#
# jq-native and umoci-native are already do_image_oci dependencies
# via image-oci.bbclass.

do_set_oci_ref_name() {
    local image_name="${IMAGE_NAME}${IMAGE_NAME_SUFFIX}-oci"
    local ref_name="${IMAGE_BASENAME}:${OCI_IMAGE_TAG}"
    local oci_dir="${IMGDEPLOYDIR}/$image_name"
    local index="$oci_dir/index.json"
    local tar_file="${IMGDEPLOYDIR}/$image_name.tar"

    if [ ! -f "$index" ]; then
        bbwarn "oci-image-adjust: index.json not found at $index, skipping"
        return
    fi

    # Set the created timestamp to actual build time. umoci handles updating
    # the config blob, manifest, and index.json internally.
    local build_date="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    bbnote "oci-image-adjust: Setting created timestamp to $build_date"
    umoci config --image "$oci_dir:${OCI_IMAGE_TAG}" --created "$build_date"

    bbnote "oci-image-adjust: Setting ref name to $ref_name"
    jq --arg ref "$ref_name" \
        '.manifests[].annotations["org.opencontainers.image.ref.name"] = $ref' \
        "$index" > "$index.new" && mv "$index.new" "$index"

    if [ -f "$tar_file" ]; then
        bbnote "oci-image-adjust: Rebuilding OCI tar"
        (cd "$oci_dir" && tar -cf "$tar_file" ".")
    fi
}

do_image_oci[postfuncs] += "do_set_oci_ref_name"
