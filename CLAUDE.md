# pelinkovac-tonik

Developer dotfiles and terminal setup for Ghostty + tmux + Neovim on macOS.

## Deploying configs

Always use `./install.sh` to deploy config changes — never copy files manually.

```bash
./install.sh
```

This installs nvim, tmux, Ghostty, and rainfrog configs, reloads the active tmux session, and verifies required tools.

## Key config files

- `config/tmux/tmux.conf` → `~/.tmux.conf`
- `config/ghostty/config` → `~/Library/Application Support/com.mitchellh.ghostty/config`
- `config/nvim/init.lua` → `~/.config/nvim/init.lua`
- `config/rainfrog/rainfrog_config.toml` → `~/Library/Application Support/dev.rainfrog.rainfrog/rainfrog_config.toml`

## Committing

Commit changes before or after running `./install.sh`. Do not skip the install script.
