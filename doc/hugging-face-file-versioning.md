# Hugging Face File Versioning: A Practical Guide

## TL;DR

Every repository on Hugging Face (HF) is a git repository. Files are versioned by commit, and you can construct stable, immutable download URLs by pinning to a specific **commit hash** instead of a branch like `main`.

- **Unstable** (tracks latest): `https://huggingface.co/<org>/<repo>/resolve/main/<file>`
- **Stable** (pinned forever): `https://huggingface.co/<org>/<repo>/resolve/<full-commit-hash>/<file>`

Use the full 40-character commit hash, not the short 7-character form.

---

## How it works under the hood

Every model, dataset, and Space on HF is backed by a real git repository. Large binary files (model weights, tokenizers, etc.) are handled by either Git LFS (Large File Storage) or Xet, HF's newer content-addressable storage system. Both systems store file blobs indexed by content hash, so identical content is never stored twice and file integrity is verifiable.

When you request a file via the `/resolve/` URL pattern, HF looks up which blob was present at the specified revision and serves that exact blob. Because blobs are content-addressed, pinning to a commit hash gives you a URL whose bytes cannot change out from under you.

## The URL format

The general pattern for downloading any file from a HF repo is:

```
https://huggingface.co/<org>/<repo>/resolve/<revision>/<path/to/file>
```

For datasets, prepend `datasets/`:

```
https://huggingface.co/datasets/<org>/<repo>/resolve/<revision>/<path/to/file>
```

The `<revision>` field accepts three things:

1. **A branch name** (e.g. `main`). Tracks the tip of that branch. Changes whenever someone pushes.
2. **A git tag** (e.g. `v2.0.1`). Usually stable, but tags can be moved by the repo owner.
3. **A full-length commit hash** (e.g. `4d33b01d79672f27f001f6abade33f22d993b151`). Cryptographically bound to the file content. This is the only option that is truly immutable.

## Why branches are not stable

A URL like:

```
https://huggingface.co/google/pegasus-xsum/resolve/main/config.json
```

always returns whatever `config.json` is currently at the tip of `main`. If the org pushes a new commit that modifies or replaces `config.json`, the URL silently starts serving the new content. For reproducibility, production deployments, or caching, this is a problem.

## Why commit hashes are stable

A URL like:

```
https://huggingface.co/google/pegasus-xsum/resolve/4d33b01d79672f27f001f6abade33f22d993b151/config.json
```

points to the state of the repo at that specific commit. The commit hash is a SHA-1 of the commit's tree plus metadata, so any change to any file in the repo at that commit would produce a different hash. As long as the commit still exists in the repo's history, the URL will return the same bytes forever.

Note the constraint: you must use the **full-length hash**. The shortened 7-character form that appears in some UIs will not resolve.

## How to find the commit hash for a file

There are three practical ways.

### 1. Via the web UI

Go to the repo's **Files and versions** tab. Next to each file, you'll see the commit message for the commit that last touched that file, along with a short hash. Click through to get the full hash, or click the **History** tab to browse all commits.

### 2. Via git

Clone the repo and use standard git tooling:

```bash
git clone https://huggingface.co/google/pegasus-xsum
cd pegasus-xsum
git log --oneline config.json
git rev-parse HEAD
```

### 3. Via the Hub API

HF exposes a simple HTTP API for metadata. To list files and their blob info at a given revision:

```bash
curl https://huggingface.co/api/models/google/pegasus-xsum/tree/main
```

To get commit history:

```bash
curl https://huggingface.co/api/models/google/pegasus-xsum/commits/main
```

Replace `models` with `datasets` or `spaces` for those repo types.

## Using pinned revisions from Python

If you're using the `huggingface_hub` library, pass the commit hash as the `revision` argument:

```python
from huggingface_hub import hf_hub_download

path = hf_hub_download(
    repo_id="google/pegasus-xsum",
    filename="config.json",
    revision="4d33b01d79672f27f001f6abade33f22d993b151",
)
```

The same `revision` argument works with the `transformers` `from_pretrained` methods:

```python
from transformers import AutoModel

model = AutoModel.from_pretrained(
    "google/pegasus-xsum",
    revision="4d33b01d79672f27f001f6abade33f22d993b151",
)
```

## Downloading via curl or wget

The `/resolve/` URL works with any HTTP client. For LFS- or Xet-backed files, HF issues a redirect to a signed CDN (Content Delivery Network) URL, so pass `-L` to follow redirects:

```bash
curl -L -o config.json \
  https://huggingface.co/google/pegasus-xsum/resolve/4d33b01d79672f27f001f6abade33f22d993b151/config.json
```

The signed CDN URL itself expires after a short window, but the `/resolve/<hash>/...` URL you hand around is permanent. HF re-signs the redirect target on every request.

## Caveats

A few things to be aware of.

**Pinning protects against content changes, not repo deletion.** If the repo owner deletes the repo, makes it private, or removes the file in a later commit, your pinned URL will return 404 or 401. The commit-hash URL works as long as the commit still exists in the public repo's history.

**Tags can be moved.** Unlike commit hashes, git tags are mutable references. A repo owner can delete and re-create a tag pointing to a different commit. If you need true immutability, prefer the commit hash.

**Gated models require authentication.** Some repos (e.g. Llama, Gemma) require accepting a license before download. Pinning to a commit hash does not bypass this. You'll need to supply an HF access token via the `Authorization: Bearer <token>` header.

**Verify integrity if you need defense in depth.** Git history on HF can technically be rewritten by a repo owner with push access (though this is strongly discouraged and rare in practice on public repos). If you're building something where a malicious repo takeover would be catastrophic, record the SHA-256 of each file at pin time and verify on download.

## Summary table

| Revision type  | Example                                        | Stable?               | When to use                                    |
| -------------- | ---------------------------------------------- | --------------------- | ---------------------------------------------- |
| Branch name    | `main`                                         | No                    | Prototyping, always-latest consumers           |
| Tag            | `v2.0.1`                                       | Mostly (movable)      | Human-readable releases                        |
| Commit hash    | `4d33b01d79672f27f001f6abade33f22d993b151`     | Yes (content-bound)   | Production, reproducibility, caching, citing   |

## One-liner to remember

> If you want the URL to keep returning the exact same bytes, put the full commit hash in the `resolve/...` path instead of `main`.
