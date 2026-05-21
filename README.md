# oe-ai-playground

An OpenEmbedded/Yocto-based build system that produces minimal OCI container images running
[llama-server](https://github.com/ggerganov/llama.cpp) for LLM inference. Models are fetched
from Hugging Face Hub at build time and baked into the image. The resulting containers expose
an OpenAI-compatible HTTP API and can be run with `podman` or any OCI-compatible runtime.

The custom layer `meta-bradfa-ai-distro` holds the distro configuration, model fetch recipes,
container image recipes, and the two reusable BitBake classes that make adding a new model a
~10-line recipe rather than 40 lines of boilerplate.

## Submodules

| Submodule | Purpose |
|---|---|
| `openembedded-core` | OE core layer |
| `bitbake` | BitBake build tool |
| `meta-openembedded` | Extended recipe collection |
| `meta-virtualization` | Container and OCI image support |
| `meta-ai` | llama.cpp package recipes |

## Prerequisites

Install the OE build host dependencies listed in the
[Yocto Project system requirements](https://docs.yoctoproject.org/singleindex.html#system-requirements).

Also required:
- `podman` - to run the built container images
- `curl` and `jq` - for the helper scripts

## Getting Started

```
git clone <repo-url>
cd oe-ai-playground
git submodule update --init --recursive
source openembedded-core/oe-init-build-env build
```

`build/conf/local.conf` defaults to `MACHINE = "qemux86-64"` and
`DISTRO = "bradfa-container-distro"`. No changes are required for a standard build.

## Building an Image

```
bitbake bradfa-container-llama-cpp-qwen3p5-0p8b-image
```

The OCI image layout lands in:

```
build/tmp/deploy/images/qemux86-64/<image-name>-latest-oci/
```

## Running the Container

Use the `oci:` transport to run directly from the deploy directory without importing into the
local image store:

```
podman run --rm -p 8080:8080 \
  oci:$(pwd)/build/tmp/deploy/images/qemux86-64/bradfa-container-llama-cpp-qwen3p5-0p8b-image-latest-oci:latest
```

> Use `oci:` not `dir:`. The output is an OCI image layout (`index.json`), not a Docker image
> layout (`manifest.json`).

## Testing the API

`llama-server` listens on port 8080 and exposes an OpenAI-compatible API at
`http://localhost:8080/v1`. For an interactive multi-turn chat session:

```
scripts/llmchat.sh 127.0.0.1 8080
```

To check available models directly:

```
curl http://localhost:8080/v1/models
```

## Scripts

### `scripts/hf-lookup.sh`

Takes a Hugging Face file browser URL and prints the four variables needed in a
`huggingface-model` recipe:

```
scripts/hf-lookup.sh https://huggingface.co/unsloth/Qwen3.5-0.8B-GGUF/blob/main/Qwen3.5-0.8B-BF16.gguf
```

Outputs `HF_ORG`, `HF_REPO`, `HF_FILE`, and `HF_COMMIT` ready to paste into a recipe. Requires
`curl` and `jq`.

### `scripts/llmchat.sh`

Interactive command-line chat client that maintains conversation history across turns. Connects
to any OpenAI-compatible API endpoint:

```
scripts/llmchat.sh [--model=NAME] [--system=TEXT] HOST PORT
```

## Classes

### `huggingface-model.bbclass`

Use this for model fetch recipes under `recipes-llm-models/<org>/`.

Fetches a single GGUF file from Hugging Face Hub, pins it to an immutable commit hash, and
deploys it directly to `DEPLOY_DIR_IMAGE` (bypassing the package manager, which cannot handle
multi-gigabyte files reliably). An empty package is produced so that OE's packaging machinery
generates the sstate manifests that `do_rootfs` requires.

Required variables: `HF_ORG`, `HF_REPO`, `HF_FILE`, `HF_COMMIT`, `SRC_URI[model.sha256sum]`.

See the class header and `doc/hugging-face-file-versioning.md` for details on pinning and
finding the correct commit hash.

### `llama-cpp-container-image.bbclass`

Use this for container image recipes under `recipes-images/images/`.

Encapsulates all llama-server image boilerplate: `IMAGE_FSTYPES`, `IMAGE_INSTALL`,
`OCI_IMAGE_CMD` construction, `OCI_IMAGE_ENTRYPOINT`, and rootfs post-processing. A recipe
only needs to set `LLAMA_MODEL_PACKAGE`, `LLAMA_MODEL_FILE`, and any inference parameter
overrides (`LLAMA_CTX_SIZE`, `LLAMA_REASONING_BUDGET`, etc.).

**Do not use `IMAGE_INSTALL` for model packages.** Set `LLAMA_MODEL_PACKAGE` instead - the
class wires up the `do_deploy` dependency and installs the model file from `DEPLOY_DIR_IMAGE`
via `ROOTFS_POSTPROCESS_COMMAND`.

See the class header for all available variables and defaults.

### `oci-image-adjust.bbclass`

Sets `org.opencontainers.image.ref.name` in the OCI `index.json` and stamps the image
creation timestamp. Inherited automatically by `llama-cpp-container-image`; no need to
inherit it directly in image recipes.

## Adding a New Model and Image

1. Find the model file on Hugging Face and copy the file blob URL from the web UI.
2. Run `scripts/hf-lookup.sh <url>` to get `HF_ORG`, `HF_REPO`, `HF_FILE`, and `HF_COMMIT`.
3. Create a model recipe:

   ```
   meta-bradfa-ai-distro/recipes-llm-models/<org>/<org>-<model>-<size>-<format>-<quant>_1.0.bb
   ```

   Set `SRC_URI[model.sha256sum] = ""` on first build - BitBake will report the correct value
   in the fetch error.

4. Create an image recipe:

   ```
   meta-bradfa-ai-distro/recipes-images/images/<namespace>-container-llama-cpp-<model-id>-image.bb
   ```

   Image recipe naming convention: `<namespace>-container-llama-cpp-<model-id>-image.bb`
   where `<model-id>` follows `<org>-<model>-<size>-<quant>` (dots to `p`, lowercase,
   underscores dropped), e.g. `byteshape-qwen3p6-35b-a3b-q4ks`.

5. `bitbake <image-name>`
