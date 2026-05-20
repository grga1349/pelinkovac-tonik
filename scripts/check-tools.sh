#!/usr/bin/env bash
set -euo pipefail

required=(
  git
  tmux
  nvim
  rg
)

recommended=(
  go
  npm
  tree-sitter
  lazygit
  delta
  psql
  pgcli
  rainfrog
)

optional_ai=(
  codex
  claude
)

missing=0

printf '%s\n' 'Required tools'
printf '%s\n' '--------------'
for cmd in "${required[@]}"; do
  if command -v "$cmd" >/dev/null 2>&1; then
    printf 'ok      %s\n' "$cmd"
  else
    printf 'missing %s\n' "$cmd"
    missing=1
  fi
done

printf '\n%s\n' 'Recommended tools'
printf '%s\n' '-----------------'
for cmd in "${recommended[@]}"; do
  if command -v "$cmd" >/dev/null 2>&1; then
    printf 'ok      %s\n' "$cmd"
  else
    printf 'missing %s\n' "$cmd"
  fi
done

printf '\n%s\n' 'Optional AI tools'
printf '%s\n' '-----------------'
for cmd in "${optional_ai[@]}"; do
  if command -v "$cmd" >/dev/null 2>&1; then
    printf 'ok      %s\n' "$cmd"
  else
    printf 'missing %s\n' "$cmd"
  fi
done

if ! command -v npm >/dev/null 2>&1; then
  printf '\n%s\n' 'Node note: install Node with nvm, not the OS package manager.'
fi

if command -v nvim >/dev/null 2>&1; then
  version="$(nvim --version | sed -n '1s/^NVIM v//p')"
  case "$version" in
    0.11*|0.12*|0.13*|1.*) ;;
    *)
      printf '\n%s\n' "Neovim $version detected. This config expects Neovim 0.11+."
      missing=1
      ;;
  esac
fi

exit "$missing"
