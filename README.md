# Lantern Release Artifacts

This repository hosts public release artifacts for Lantern.

## Available release

- `releases/v0.2.20/lantern-v0.2.20-x86_64-unknown-linux-gnu.tar.gz`
- `releases/v0.2.20/SHA256SUMS`
- `releases/v0.2.20/BINARY_HASHES`
- `releases/v0.2.20/peace-testnet.json`
- `releases/v0.2.20/peace-mainnet.json`
- `releases/v0.2.20/RELEASE_NOTES_v0.2.20.md`

## Verify download

From inside `releases/v0.2.20`:

```bash
sha256sum -c SHA256SUMS
```

The `BINARY_HASHES` file contains per-target binary hashes from the release build pipeline.
