#!/usr/bin/env bash
set -euo pipefail

if ! command -v brew >/dev/null 2>&1; then
  printf '%s\n' 'Homebrew is required: https://brew.sh' >&2
  exit 1
fi

brew install \
  tmux \
  neovim \
  ripgrep \
  tree-sitter-cli \
  go \
  lazygit \
  git-delta \
  postgresql@17 \
  pgcli \
  rainfrog

cat <<'EOF'

Node is intentionally not installed here.
Use nvm:
  nvm install --lts
  nvm alias default lts/*
EOF
