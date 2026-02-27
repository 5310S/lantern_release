# Lantern (Public Release Downloads)

## Start Here (macOS: Apple Silicon + Intel)

Open Terminal, then paste this:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/5310S/lantern_release/main/scripts/granny-macos.sh)
```

That is it. The installer will:
- detect your Mac architecture automatically
- download the latest macOS release
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

## Start Here (Windows x86_64)

Open PowerShell, then paste this:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/5310S/lantern_release/main/scripts/granny-windows.ps1 | iex"
```

That is it. The installer script will:
- download the latest Windows installer
- verify checksum
- launch `LanternSetup.exe`

After install:
- open `Start Menu -> Lantern -> Lantern Control Panel`
- click `Start`
- click `Refresh` after 10-20 seconds

Health check (PowerShell):

```powershell
curl.exe -k -H "Authorization: Bearer testnet-local-admin" https://127.0.0.1:8645/weave/chain/head
```

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

- Easy installers are provided for macOS (`x86_64` + `aarch64`), Linux (`x86_64`), and Windows (`x86_64`).
- Source code is private; this repository only contains public release artifacts.
