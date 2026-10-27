#!/bin/sh
#
# Stenopos installer. Downloads the Syntagma toolchain from GitHub (stenopos,
# tagma, the runtime and the standard library), verifies the release signature
# against the pinned Stenopos release key and the SHA-256, and installs it.
#
#   curl -fsSL https://raw.githubusercontent.com/Stenopos/Syntagma/main/install.sh | sh
#
# Environment overrides:
#   STENOPOS_VERSION   release tag to install (default: the newest release,
#                     release candidates included)
#   STENOPOS_INSTALL   directory for the commands (default: /usr/local/bin, or
#                     ~/.local/bin if that is not writable); the runtime and std
#                     go in ../lib/stenopos beside it
#   STENOPOS_REQUIRE_SIGNATURE=1   fail instead of warning when gpg is missing
#
# POSIX sh, no bashisms — works under dash/ash/busybox.
set -eu

REPO="Stenopos/Syntagma"
VERSION="${STENOPOS_VERSION:-latest}"
# Stenopos Release Signing primary key. Releases are signed by its CI subkey.
RELEASE_KEY_FPR="21CBC7C3F66DFAFDD0385515E5FBD28483951BCB"

err()  { printf 'error: %s\n' "$*" >&2; exit 1; }
info() { printf '%s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

# --- pick a downloader -----------------------------------------------------
if have curl; then
  dl() { curl -fsSL "$1" -o "$2"; }
  dl_stdout() { curl -fsSL "$1"; }
elif have wget; then
  dl() { wget -qO "$2" "$1"; }
  dl_stdout() { wget -qO - "$1"; }
else
  err "need curl or wget to download"
fi

# --- detect platform -------------------------------------------------------
os="$(uname -s)"
arch="$(uname -m)"
case "$os" in
  Linux) os="linux" ;;
  *) err "unsupported OS '$os' — only Linux binaries are published today. Build from source or open an issue for $os." ;;
esac
case "$arch" in
  x86_64|amd64)  arch="x86_64" ;;
  aarch64|arm64) arch="aarch64" ;;
  *) err "unsupported architecture '$arch'" ;;
esac
asset="stenopos-${os}-${arch}"

# --- resolve the version tag ----------------------------------------------
if [ "$VERSION" = "latest" ]; then
  info "Resolving the newest release..."
  # releases/latest skips pre-releases; the list is newest first and includes them.
  VERSION="$(dl_stdout "https://api.github.com/repos/${REPO}/releases?per_page=1" \
    | grep '"tag_name"' | head -1 | cut -d'"' -f4)"
  [ -n "$VERSION" ] || err "could not resolve the newest release tag"
fi
info "Installing Stenopos ${VERSION} (${asset})"

base="https://github.com/${REPO}/releases/download/${VERSION}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# --- download the toolchain, checksums and signature -------------------------
# Releases from rc.5 on ship one bundle (stenopos, tagma, runtime, std); older
# releases only the stenopos binary.
bundle="syntagma-${VERSION#v}-${os}-${arch}.tar.gz"
dl "${base}/SHA256SUMS"     "${tmp}/SHA256SUMS"    || err "download failed: SHA256SUMS"
if grep -q " ${bundle}\$" "${tmp}/SHA256SUMS"; then
  asset="$bundle"
fi
dl "${base}/${asset}"       "${tmp}/${asset}"      || err "download failed: ${asset}"
dl "${base}/SHA256SUMS.asc" "${tmp}/SHA256SUMS.asc" || err "download failed: SHA256SUMS.asc"

# --- verify the signature against the pinned release key -------------------
if have gpg; then
  info "Verifying release signature..."
  gh="${tmp}/gnupg"; mkdir -m 700 "$gh"
  gpg --batch --quiet --homedir "$gh" --import 2>/dev/null <<'KEY' || err "could not load the release key"
-----BEGIN PGP PUBLIC KEY BLOCK-----

mDMEat+E0xYJKwYBBAHaRw8BAQdAw2/MVOYQEL6NclXUZeoj0zHKGtBWCWEdZPZG
Cg5lMCG0MFN0ZW5vcG9zIFJlbGVhc2UgU2lnbmluZyA8Y2FkYW1oYXJwZXJAZ21h
aWwuY29tPoiZBBMWCgBBFiEEIcvHw/Zt+v3QOFUV5fvShIOVG8sFAmrfhNMCGwEF
CQWjmoAFCwkIBwICIgIGFQoJCAsCBBYCAwECHgcCF4AACgkQ5fvShIOVG8ukfgEA
3ucRMrTz+qdaZsISQnQbuNdQXh46hFyv54groSM1vhQBAP1+cxGcGJesBeFy1nz/
GOsdBmjYlYZX7YJj61Dc1n8MuDMEat+FkRYJKwYBBAHaRw8BAQdAhxVpGfAt0Aj3
HQrR2P7Ne/R8ZmlLHxttIpu70kWnQUyI9QQYFgoAJhYhBCHLx8P2bfr90DhVFeX7
0oSDlRvLBQJq34WRAhsCBQkDwmcAAIEJEOX70oSDlRvLdiAEGRYKAB0WIQRHquLx
kK/7gGeEnta6LogGkWXdwQUCat+FkQAKCRC6LogGkWXdwSLHAP9GO3vR0nVWX9dJ
8AU4doPmkPs+EAxnsXaGt9tVFKNTCwD/aQs5gPLqZFFYPc+FSgReBBYaxubEM+i+
nLnlq/ANsgSzCQEA3+sTbMzhZ4W7i35WVcxP5tFKwlFI1BcO2pT/TzmtXTYA/0dI
xWlcbx+mUfmIWs4xS+wbex4KzRwnytPhaVlIXh8CuDMEat+FsRYJKwYBBAHaRw8B
AQdACxFisV3IEw15GLw5kEU5XcNy5oweSYlx9EdUx/2lbMqI9QQYFgoAJhYhBCHL
x8P2bfr90DhVFeX70oSDlRvLBQJq34WxAhsCBQkDwmcAAIEJEOX70oSDlRvLdiAE
GRYKAB0WIQS+E7MkQHxXbs0FQkEcOQdihu0EZwUCat+FsQAKCRAcOQdihu0EZyTP
AP9WpP1bqgsLooSxNICgKXxOA0wEwL1/FwYuCVzSzLWSYQEAuvZGRNZaia/OZn+2
baQKze7UPZ/ezgFQdVl2UGEGfwiBvgEArviOg9k5wCVMRvoJyJ4ivAazZj4l7IN0
ANFpQCox660BANZAandy/0HweH1XF2IUDvuD7EQi8qka3dWCaspFpDEI
=Y+A9
-----END PGP PUBLIC KEY BLOCK-----
KEY
  gpg --batch --homedir "$gh" --status-fd 1 --verify "${tmp}/SHA256SUMS.asc" "${tmp}/SHA256SUMS" 2>/dev/null \
    | grep -q "^\[GNUPG:\] VALIDSIG .* ${RELEASE_KEY_FPR}\$" \
    || err "SHA256SUMS is not signed by the Stenopos release key ${RELEASE_KEY_FPR}"
  info "Signed by the Stenopos release key ${RELEASE_KEY_FPR}."
elif [ "${STENOPOS_REQUIRE_SIGNATURE:-0}" = "1" ]; then
  err "gpg is required to check the release signature (STENOPOS_REQUIRE_SIGNATURE=1)"
else
  info "warning: gpg not found; the release signature was NOT checked (SHA-256 only)."
fi

# --- verify checksum -------------------------------------------------------
info "Verifying SHA-256..."
( cd "$tmp" && grep " ${asset}\$" SHA256SUMS | { have sha256sum && sha256sum -c - || shasum -a 256 -c -; } ) \
  || err "checksum verification failed"

# --- choose an install dir -------------------------------------------------
dest="${STENOPOS_INSTALL:-/usr/local/bin}"
if [ ! -w "$dest" ] 2>/dev/null && [ "$dest" = "/usr/local/bin" ]; then
  if have sudo; then
    SUDO="sudo"
  else
    dest="${HOME}/.local/bin"; SUDO=""
    mkdir -p "$dest"
    info "note: /usr/local/bin not writable; installing to $dest (ensure it is on your PATH)"
  fi
else
  SUDO=""
  mkdir -p "$dest" 2>/dev/null || true
fi

# --- install ---------------------------------------------------------------
if [ "$asset" = "$bundle" ]; then
  mkdir -p "${tmp}/x" && tar -xzf "${tmp}/${asset}" -C "${tmp}/x" || err "could not unpack ${asset}"
  top="${tmp}/x/syntagma-${VERSION#v}-${os}-${arch}"
  lib="$(dirname "$dest")/lib/stenopos"
  ${SUDO} mkdir -p "$lib" || err "could not create ${lib}"
  ${SUDO} rm -rf "${lib}/std" "${lib}/stenopos_runtime.c"
  ${SUDO} cp -R "${top}/lib/stenopos/." "$lib/" || err "could not install to ${lib}"
  for cmd in stenopos tagma; do
    ${SUDO} install -m 0755 "${top}/bin/${cmd}" "${dest}/${cmd}" \
      || err "could not install to ${dest} (try STENOPOS_INSTALL=\$HOME/.local/bin)"
  done
  info ""
  info "Syntagma ${VERSION} installed: ${dest}/tagma, ${dest}/stenopos (runtime and std in ${lib})"
else
  ${SUDO} install -m 0755 "${tmp}/${asset}" "${dest}/stenopos" \
    || err "could not install to ${dest} (try STENOPOS_INSTALL=\$HOME/.local/bin)"
  info ""
  info "Stenopos ${VERSION} installed to ${dest}/stenopos"
fi
if have stenopos && [ "$(command -v stenopos)" = "${dest}/stenopos" ]; then
  stenopos version 2>/dev/null | tail -1 >&2 || true
else
  info "Add ${dest} to your PATH, then run: tagma new hello && cd hello && tagma run"
fi
info ""
info "Stenopos needs 'llc' (LLVM 14 or newer) and 'cc' (a C compiler) at compile time."
info "  Debian/Ubuntu:  sudo apt-get install -y llvm clang"
info "  macOS (brew):   brew install llvm"
