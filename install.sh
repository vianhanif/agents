#!/usr/bin/env bash
# install.sh — symlink this repo into ~/.agents
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$HOME/.agents"

# 1. Back up existing ~/.agents if it exists and isn't a symlink
if [ -e "$TARGET" ] && [ ! -L "$TARGET" ]; then
  mv "$TARGET" "${TARGET}.bak.$(date +%s)"
fi

# 2. Symlink the repo into ~/.agents
ln -sfn "$REPO_DIR" "$TARGET"

# 3. Create .env if it doesn't exist
if [ ! -f "$REPO_DIR/.env" ]; then
  cp "$REPO_DIR/env.template" "$REPO_DIR/.env"
  echo "Created .env from env.template. Fill in your real secrets."
fi

echo "Agents repo linked to ~/.agents"
