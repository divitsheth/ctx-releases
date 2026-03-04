#!/bin/sh
# Install script for ctx — project memory for AI agents
# Usage: curl -fsSL https://raw.githubusercontent.com/divitsheth/ctx-releases/main/install.sh | sh
set -e

REPO="divitsheth/ctx-releases"

# Detect OS
OS="$(uname -s)"
case "$OS" in
  Darwin)  OS="darwin" ;;
  Linux)   OS="linux" ;;
  *)       echo "Error: unsupported OS: $OS" >&2; exit 1 ;;
esac

# Detect architecture
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)  ARCH="amd64" ;;
  aarch64) ARCH="arm64" ;;
  arm64)   ARCH="arm64" ;;
  *)       echo "Error: unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

# Fetch latest version from GitHub API
echo "Fetching latest version..."
VERSION="$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')"
if [ -z "$VERSION" ]; then
  echo "Error: could not determine latest version" >&2
  exit 1
fi
echo "Latest version: v${VERSION}"

# Build download URL
ARCHIVE="ctx_${VERSION}_${OS}_${ARCH}.tar.gz"
URL="https://github.com/${REPO}/releases/download/v${VERSION}/${ARCHIVE}"
CHECKSUMS_URL="https://github.com/${REPO}/releases/download/v${VERSION}/checksums.txt"

# Create temp directory
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

# Download archive and checksums
echo "Downloading ctx v${VERSION} for ${OS}/${ARCH}..."
curl -fsSL -o "${TMPDIR}/${ARCHIVE}" "$URL"
curl -fsSL -o "${TMPDIR}/checksums.txt" "$CHECKSUMS_URL"

# Verify checksum
echo "Verifying checksum..."
cd "$TMPDIR"
EXPECTED="$(grep "${ARCHIVE}" checksums.txt | awk '{print $1}')"
if [ -z "$EXPECTED" ]; then
  echo "Error: checksum not found for ${ARCHIVE}" >&2
  exit 1
fi

if command -v sha256sum > /dev/null 2>&1; then
  ACTUAL="$(sha256sum "${ARCHIVE}" | awk '{print $1}')"
elif command -v shasum > /dev/null 2>&1; then
  ACTUAL="$(shasum -a 256 "${ARCHIVE}" | awk '{print $1}')"
else
  echo "Warning: no sha256 tool found, skipping checksum verification" >&2
  ACTUAL="$EXPECTED"
fi

if [ "$EXPECTED" != "$ACTUAL" ]; then
  echo "Error: checksum mismatch" >&2
  echo "  expected: $EXPECTED" >&2
  echo "  actual:   $ACTUAL" >&2
  exit 1
fi
echo "Checksum verified."

# Extract
tar xzf "${ARCHIVE}"

# Install
INSTALL_DIR="/usr/local/bin"
if [ ! -w "$INSTALL_DIR" ] 2>/dev/null; then
  INSTALL_DIR="${HOME}/.local/bin"
  mkdir -p "$INSTALL_DIR"
fi

cp ctx "${INSTALL_DIR}/ctx"
chmod +x "${INSTALL_DIR}/ctx"

echo "Installed ctx v${VERSION} to ${INSTALL_DIR}/ctx"

# Check if install dir is in PATH
case ":$PATH:" in
  *":${INSTALL_DIR}:"*) ;;
  *) echo "Note: add ${INSTALL_DIR} to your PATH" ;;
esac
