#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
install_dotfiles=1

usage() {
  cat <<'EOF'
Usage: ./install.sh [--no-dotfiles]

Installs the ptx command and optionally copies the bundled editor/terminal config.
This script does not install system packages.

Options:
  --no-dotfiles  Install only the ptx shell alias
  -h, --help     Show this help

Package install scripts are separate:
  ./scripts/install-macos.sh
  ./scripts/install-ubuntu.sh
  ./scripts/install-arch.sh
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-dotfiles)
      install_dotfiles=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'install.sh: unknown option %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

backup_path() {
  local path="$1"
  if [[ -e "$path" || -L "$path" ]]; then
    local stamp
    stamp="$(date +%Y%m%d%H%M%S)"
    mv "$path" "$path.backup-$stamp"
  fi
}

install_file() {
  local source="$1"
  local target="$2"
  mkdir -p "$(dirname "$target")"
  backup_path "$target"
  cp "$source" "$target"
}

install_alias() {
  local zshrc="${ZDOTDIR:-$HOME}/.zshrc"
  mkdir -p "$(dirname "$zshrc")"
  touch "$zshrc"

  if grep -Fq 'alias ptx=' "$zshrc"; then
    sed -i.bak "s#^alias ptx=.*#alias ptx=\"$repo_dir/bin/ptx\"#" "$zshrc"
  else
    printf '\n%s\n' "alias ptx=\"$repo_dir/bin/ptx\"" >> "$zshrc"
  fi

  printf '%s\n' "Installed ptx alias in $zshrc"
}

install_configs() {
  install_file "$repo_dir/config/nvim/init.lua" "$HOME/.config/nvim/init.lua"
  install_file "$repo_dir/config/tmux/tmux.conf" "$HOME/.tmux.conf"
  install_file "$repo_dir/config/tmux/vscode-dark-plus.tmux" "$HOME/.config/tmux/vscode-dark-plus.tmux"

  case "$(uname -s)" in
    Darwin)
      install_file "$repo_dir/config/ghostty/config" "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
      ;;
    Linux)
      install_file "$repo_dir/config/ghostty/config" "$HOME/.config/ghostty/config"
      ;;
  esac
}

chmod +x "$repo_dir"/bin/* "$repo_dir"/scripts/*.sh
install_alias

if [[ "$install_dotfiles" -eq 1 ]]; then
  install_configs
  printf '%s\n' 'Installed Neovim, tmux, and Ghostty config.'
fi

printf '\n%s\n' 'Tool check:'
if "$repo_dir/scripts/check-tools.sh"; then
  printf '%s\n' 'All required tools are present.'
else
  printf '%s\n' 'Required tools are missing. See the package scripts in ./scripts/.' >&2
fi

printf '\n%s\n' 'Done. Reload your shell or run: source ~/.zshrc'
