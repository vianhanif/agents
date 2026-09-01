#!/usr/bin/env bash
# install.sh — move this repo into ~/.agents
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$HOME/.agents"

if [ "$REPO_DIR" = "$TARGET" ]; then
  echo "Already installed at $TARGET."
else
  # 1. Back up or remove any existing ~/.agents
  if [ -L "$TARGET" ]; then
    rm "$TARGET"
  elif [ -e "$TARGET" ]; then
    mv "$TARGET" "${TARGET}.bak.$(date +%s)"
  fi

  # 2. Move the repo into ~/.agents
  mv "$REPO_DIR" "$TARGET"
  echo "Moved repo to $TARGET"
fi

# 3. Create .env from template if missing
if [ ! -f "$TARGET/.env" ]; then
  cp "$TARGET/env.template" "$TARGET/.env"
  echo "Created .env from env.template. Fill in your real secrets."
fi

echo "Done. Agents installed at $TARGET"
