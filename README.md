# Lantern (Public Release Downloads)

If you are not technical, use the **one-line install** below.

## Start Here (Linux x86_64)

Open Terminal, then paste this:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/5310S/lantern_release/main/scripts/granny-linux.sh)
```

That is it. The installer will:
- download the latest Lantern release
- verify checksum
- initialize testnet data
- rotate node identity
- create `~/lantern/start.sh`

Then start your node with:

```bash
~/lantern/start.sh
```

In another Terminal, check health:

```bash
curl -ks -H "Authorization: Bearer $LANTERN_HTTP_TOKEN" https://127.0.0.1:8645/weave/chain/head
```

## Current Release

- Version: `v0.2.20`
- Manifest: [`latest.json`](./latest.json)
- Artifacts: [`releases/v0.2.20`](./releases/v0.2.20)

## Manual Verify

From `releases/v0.2.20`:

```bash
sha256sum -c SHA256SUMS
```

## Notes

- Current easy installer is Linux `x86_64` only.
- Source code is private; this repository only contains public release artifacts.
