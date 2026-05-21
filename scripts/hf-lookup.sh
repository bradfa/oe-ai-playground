#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<EOF
Usage: $(basename "$0") HF-BLOB-URL

Parse a Hugging Face file browser URL and print the four variables needed to
write a BitBake recipe that uses the huggingface-model class.

The URL must be a file blob link from the HF web interface, e.g.:
  https://huggingface.co/unsloth/Qwen3.5-0.8B-GGUF/blob/main/Qwen3.5-0.8B-BF16.gguf
  https://huggingface.co/datasets/myorg/myrepo/blob/main/subdir/data.bin

Output is ready to paste into a recipe. Leave SRC_URI[model.sha256sum] as ""
and BitBake will report the correct value in the fetch error on first build.

Options:
  -h, --help   Show this help

Requirements: curl, jq
EOF
    exit 0
}

if [[ $# -eq 0 ]]; then
    echo "Error: HF-BLOB-URL is required." >&2
    echo "Run with --help for usage." >&2
    exit 1
fi

case "$1" in
    -h|--help) usage ;;
    -*)        echo "Error: unknown option: $1" >&2; exit 1 ;;
esac

URL="$1"

# Strip scheme and host
path="${URL#https://huggingface.co/}"

if [[ "$path" == "$URL" ]]; then
    echo "Error: URL must start with https://huggingface.co/" >&2
    exit 1
fi

# Detect datasets repos (path starts with "datasets/")
api_type="models"
if [[ "$path" == datasets/* ]]; then
    api_type="datasets"
    path="${path#datasets/}"
fi

# Parse org, repo, "blob", branch, and file path using prefix stripping so
# that subdirectory file paths (e.g. subdir/file.gguf) are preserved intact.
org="${path%%/*}";    path="${path#*/}"
repo="${path%%/*}";   path="${path#*/}"
blob="${path%%/*}";   path="${path#*/}"
branch="${path%%/*}"; hf_file="${path#*/}"

if [[ "$blob" != "blob" ]]; then
    echo "Error: expected a /blob/ URL from the HF file browser, got: $URL" >&2
    exit 1
fi

if [[ -z "$org" || -z "$repo" || -z "$branch" || -z "$hf_file" ]]; then
    echo "Error: could not parse org, repo, branch, or file from: $URL" >&2
    exit 1
fi

# Fetch the HEAD commit hash for the branch from the HF API
api_url="https://huggingface.co/api/${api_type}/${org}/${repo}/commits/${branch}"
if ! api_response="$(curl -sf "$api_url")"; then
    echo "Error: could not fetch commit list from ${api_url}" >&2
    echo "Check that the repo exists and is public." >&2
    exit 1
fi

commit="$(jq -r '.[0].id' <<< "$api_response")"

if [[ -z "$commit" || "$commit" == "null" ]]; then
    echo "Error: could not parse commit hash from API response at ${api_url}" >&2
    exit 1
fi

cat <<EOF
HF_ORG    = "${org}"
HF_REPO   = "${repo}"
HF_FILE   = "${hf_file}"
HF_COMMIT = "${commit}"
SRC_URI[model.sha256sum] = ""

# Leave SRC_URI[model.sha256sum] = ""; BitBake reports the correct value on first build.
EOF
