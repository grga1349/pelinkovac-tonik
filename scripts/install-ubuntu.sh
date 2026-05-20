#!/usr/bin/env bash
set -euo pipefail

if ! command -v apt-get >/dev/null 2>&1; then
  printf '%s\n' 'apt-get not found. This script is for Ubuntu/Debian systems.' >&2
  exit 1
fi

sudo apt-get update
sudo apt-get install -y \
  git \
  tmux \
  neovim \
  ripgrep \
  curl \
  build-essential \
  golang-go \
  postgresql-client \
  pgcli

cat <<'EOF'

Optional tools may need separate upstream installs depending on your Ubuntu release:
  lazygit
  delta
  rainfrog
  tree-sitter CLI

Node is intentionally not installed here.
Use nvm:
  nvm install --lts
  nvm alias default lts/*
EOF
