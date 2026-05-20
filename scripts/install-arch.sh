#!/usr/bin/env bash
set -euo pipefail

if ! command -v pacman >/dev/null 2>&1; then
  printf '%s\n' 'pacman not found. This script is for Arch Linux.' >&2
  exit 1
fi

sudo pacman -Syu --needed \
  git \
  tmux \
  neovim \
  ripgrep \
  tree-sitter-cli \
  go \
  lazygit \
  git-delta \
  postgresql-libs \
  pgcli

cat <<'EOF'

Optional tools may need AUR/upstream installs:
  rainfrog

Node is intentionally not installed here.
Use nvm:
  nvm install --lts
  nvm alias default lts/*
EOF
