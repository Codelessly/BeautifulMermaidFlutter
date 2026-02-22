#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSET_DIR="$ROOT_DIR/assets"
OUT_JS="$ASSET_DIR/beautiful-mermaid.browser.global.js"
TMP_DIR="$(mktemp -d)"
REPO_DIR="$TMP_DIR/beautiful-mermaid"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo "[1/4] Cloning lukilabs/beautiful-mermaid (main)..."
git clone --depth 1 --branch main https://github.com/lukilabs/beautiful-mermaid.git "$REPO_DIR"

cd "$REPO_DIR"
COMMIT_SHA="$(git rev-parse --short HEAD)"
COMMIT_DATE="$(git show -s --format=%cI HEAD)"

echo "[2/4] Installing dependencies and building..."
if command -v bun >/dev/null 2>&1; then
  bun install
  bun run build
elif command -v npm >/dev/null 2>&1; then
  npm install
  npm run build
else
  echo "Error: neither bun nor npm is installed." >&2
  exit 1
fi

echo "[3/4] Copying build outputs into package assets..."
mkdir -p "$ASSET_DIR"
cp "$REPO_DIR/dist/beautiful-mermaid.browser.global.js" "$OUT_JS"
rm -f "$ASSET_DIR/beautiful-mermaid.browser.global.js.map"

echo "[4/4] Done."
echo "Updated bundle from commit: $COMMIT_SHA ($COMMIT_DATE)"
if command -v shasum >/dev/null 2>&1; then
  echo "SHA256:"
  shasum -a 256 "$OUT_JS"
fi
