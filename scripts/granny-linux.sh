#!/usr/bin/env bash
set -euo pipefail

REPO_RAW_BASE="${REPO_RAW_BASE:-https://raw.githubusercontent.com/5310S/lantern_release/main}"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

say() {
  printf "\n%s\n" "$*"
}

die() {
  printf "\nERROR: %s\n" "$*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

sha256_file() {
  local file="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | awk '{print $1}'
  else
    die "Missing checksum tool (need sha256sum or shasum)."
  fi
}

require_cmd curl
require_cmd tar
require_cmd uname

say "Lantern Easy Install (Linux x86_64)"
say "This script downloads Lantern, verifies the checksum, and sets up testnet."

curl -fsSL "${REPO_RAW_BASE}/latest.env" -o "${WORK_DIR}/latest.env" \
  || die "Could not load release metadata from ${REPO_RAW_BASE}/latest.env"
# shellcheck source=/dev/null
source "${WORK_DIR}/latest.env"

ARCH="$(uname -m)"
if [[ "${ARCH}" != "x86_64" && "${ARCH}" != "amd64" ]]; then
  die "This installer currently supports Linux x86_64 only. Detected: ${ARCH}"
fi

INSTALL_ROOT="${INSTALL_ROOT:-${HOME}/lantern}"
DATA_DIR="${DATA_DIR:-${HOME}/.lantern/${CHAIN_ID}}"

read -r -p "Install Lantern into ${INSTALL_ROOT}? [Y/n] " reply
reply="${reply:-Y}"
if [[ ! "$reply" =~ ^[Yy]$ ]]; then
  die "Install cancelled by user."
fi

USER_ADDR="${LANTERN_USER_ADDR:-${DEFAULT_USER_ADDR}}"
read -r -p "Use default testnet wallet address (${DEFAULT_USER_ADDR})? [Y/n] " addr_reply
addr_reply="${addr_reply:-Y}"
if [[ "$addr_reply" =~ ^[Nn]$ ]]; then
  read -r -p "Enter your testnet wallet address (tpc...): " USER_ADDR
  [[ -n "${USER_ADDR}" ]] || die "Wallet address is required."
fi

ASSET_URL="${REPO_RAW_BASE}/releases/${VERSION}/${TARBALL}"
DOWNLOAD_PATH="${WORK_DIR}/${TARBALL}"

say "Downloading ${TARBALL} ..."
curl -fL --retry 3 --retry-delay 1 "${ASSET_URL}" -o "${DOWNLOAD_PATH}" \
  || die "Download failed: ${ASSET_URL}"

say "Verifying checksum ..."
ACTUAL_SHA="$(sha256_file "${DOWNLOAD_PATH}")"
if [[ "${ACTUAL_SHA}" != "${TARBALL_SHA256}" ]]; then
  die "Checksum mismatch. Expected ${TARBALL_SHA256}, got ${ACTUAL_SHA}"
fi

VERSION_DIR="${INSTALL_ROOT}/${VERSION}"
mkdir -p "${INSTALL_ROOT}"
rm -rf "${VERSION_DIR}"
mkdir -p "${VERSION_DIR}"

tar -xzf "${DOWNLOAD_PATH}" -C "${VERSION_DIR}" || die "Extract failed"

EXTRACT_ROOT="$(find "${VERSION_DIR}" -mindepth 1 -maxdepth 1 -type d | head -n1)"
[[ -n "${EXTRACT_ROOT}" ]] || die "Could not locate extracted directory"
[[ -x "${EXTRACT_ROOT}/lantern" ]] || die "lantern binary missing after extraction"
[[ -x "${EXTRACT_ROOT}/init_peace_testnet" ]] || die "init_peace_testnet binary missing after extraction"

ln -sfn "${EXTRACT_ROOT}" "${INSTALL_ROOT}/current"
mkdir -p "${DATA_DIR}"

say "Initializing deterministic chain data ..."
"${INSTALL_ROOT}/current/init_peace_testnet" \
  --chain-id "${CHAIN_ID}" \
  --bundle "${INSTALL_ROOT}/current/dist/peace-testnet.json" \
  --data-dir "${DATA_DIR}" \
  --user-addr "${USER_ADDR}"

say "Initializing node config ..."
"${INSTALL_ROOT}/current/lantern" node init \
  --role full \
  --data-dir "${DATA_DIR}" \
  --chain-id "${CHAIN_ID}" \
  --p2p-port 3000 \
  --rpc-port 8645 \
  --bootstrap "${BOOTSTRAP}"

say "Rotating identity ..."
"${INSTALL_ROOT}/current/lantern" node rotate-identity --data-dir "${DATA_DIR}"

cat > "${INSTALL_ROOT}/start.sh" <<START_SCRIPT
#!/usr/bin/env bash
set -euo pipefail
export LANTERN_HTTP_TOKEN=\${LANTERN_HTTP_TOKEN:-testnet-local-admin}
exec "${INSTALL_ROOT}/current/lantern" node run --data-dir "${DATA_DIR}"
START_SCRIPT
chmod +x "${INSTALL_ROOT}/start.sh"

say "Install complete."
echo ""
echo "Start node:"
echo "  ${INSTALL_ROOT}/start.sh"
echo ""
echo "Check health in another terminal:"
echo "  curl -ks -H \"Authorization: Bearer \$LANTERN_HTTP_TOKEN\" https://127.0.0.1:8645/weave/chain/head"
