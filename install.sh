#!/bin/sh
#
# Stenopos installer. Downloads the right release binary from GitHub, verifies
# its SHA-256 (and GPG signature if available), and installs it.
#
#   curl -fsSL https://raw.githubusercontent.com/Stenopos/Syntagma/main/install.sh | sh
#
# Environment overrides:
#   STENOPOS_VERSION   release tag to install (default: latest)
#   STENOPOS_INSTALL   install directory (default: /usr/local/bin, or ~/.local/bin
#                     if that is not writable)
#
# POSIX sh, no bashisms — works under dash/ash/busybox.
set -eu

REPO="Stenopos/Syntagma"
VERSION="${STENOPOS_VERSION:-latest}"

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
  info "Resolving latest release..."
  VERSION="$(dl_stdout "https://api.github.com/repos/${REPO}/releases/latest" \
    | grep '"tag_name"' | head -1 | cut -d'"' -f4)"
  [ -n "$VERSION" ] || err "could not resolve the latest release tag"
fi
info "Installing Stenopos ${VERSION} (${asset})"

base="https://github.com/${REPO}/releases/download/${VERSION}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# --- download binary + checksums (+ optional signature) --------------------
dl "${base}/${asset}"       "${tmp}/${asset}"      || err "download failed: ${asset}"
dl "${base}/SHA256SUMS"     "${tmp}/SHA256SUMS"    || err "download failed: SHA256SUMS"
dl "${base}/SHA256SUMS.asc" "${tmp}/SHA256SUMS.asc" 2>/dev/null || true

# --- verify checksum -------------------------------------------------------
info "Verifying SHA-256..."
( cd "$tmp" && grep " ${asset}\$" SHA256SUMS | { have sha256sum && sha256sum -c - || shasum -a 256 -c -; } ) \
  || err "checksum verification failed"

# --- verify signature if a public key + gpg are available ------------------
if [ -f "${tmp}/SHA256SUMS.asc" ] && have gpg; then
  if gpg --verify "${tmp}/SHA256SUMS.asc" "${tmp}/SHA256SUMS" >/dev/null 2>&1; then
    info "GPG signature verified."
  else
    info "note: GPG signature present but not verified (import the Stenopos signing key to check it)."
  fi
fi

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
${SUDO} install -m 0755 "${tmp}/${asset}" "${dest}/stenopos" \
  || err "could not install to ${dest} (try STENOPOS_INSTALL=\$HOME/.local/bin)"

info ""
info "Stenopos ${VERSION} installed to ${dest}/stenopos"
if have stenopos && [ "$(command -v stenopos)" = "${dest}/stenopos" ]; then
  stenopos version 2>/dev/null | tail -1 >&2 || true
else
  info "Add ${dest} to your PATH, then run: stenopos version"
fi
info ""
info "Stenopos needs 'llc' (LLVM) and 'cc' (a C compiler) at compile time."
info "  Debian/Ubuntu:  sudo apt-get install -y llvm clang"
info "  macOS (brew):   brew install llvm"
