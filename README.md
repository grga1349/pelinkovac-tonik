# ptx / pelinkovac-tonik

`ptx` is a small Bash CLI facade for launching tmux dev workspaces.

It detects the current git repo, names the tmux session after the repo folder, attaches to an existing session when one exists, and otherwise creates a ready-to-work layout with terminal, agent, runner, diff, editor, and optional DB windows. The default AI pane is present but does not start Codex until you run it.

## Install

```sh
./install.sh
```

The main installer installs the `ptx` alias, zsh completions, and bundled dotfiles. It does not install system packages.

To only install the command alias and completions:

```sh
./install.sh --no-dotfiles
```

To check missing tools without installing anything:

```sh
./scripts/check-tools.sh
```

Package scripts are separate and can be run manually:

```sh
./scripts/install-macos.sh
./scripts/install-ubuntu.sh
./scripts/install-arch.sh
```

Node is intentionally not installed by those scripts. Use `nvm`.

## Usage

Run `ptx` inside a git repo:

```sh
ptx
```

Or point it at a repo:

```sh
ptx ~/Projects/my-app
```

Command shape:

```sh
ptx [command|preset] [options]
```

Commands:

```sh
ptx help      # show help
ptx keys      # show keybindings
```

## Presets

```sh
ptx           # default workspace with term, agent, diff, edit, db shell
ptx short     # shell + editor only
ptx full      # default + running db client
ptx heavy     # two AI panes + two runners + running db client
ptx ai        # codex + claude mode
ptx run2      # two runner mode
ptx db        # default + running db client
```

Fun aliases:

```sh
ptx dry       # short
ptx classic   # legacy default with Codex and one runner
ptx strong    # full
ptx double    # heavy
ptx neat      # term + edit, no AI, no runner
```

## Options

```sh
--ai codex|claude|both|none
--runner none|one|two
--db           # create db window and start a db client
--no-db        # skip db window
--editor nvim|hx|none
--diff lazygit|delta|none
--reset
--kill
--keys
```

## Layouts

Default:

1. `term`: home shell + repo shell
2. `agent`: Codex-ready shell + runner
3. `diff`: live diff / lazygit
4. `edit`: editor
5. `db`: shell only

Classic:

1. `term`: home shell + repo shell
2. `agent`: Codex + runner
3. `diff`: live diff / lazygit
4. `edit`: editor
5. `db`: shell only

Heavy:

1. `term`
2. `agent`: codex + claude
3. `run`: runner + runner2
4. `diff`
5. `edit`
6. `db`

## Defaults

- Editor: `nvim`
- AI: Codex pane is created but Codex is not launched
- Runner: one runner pane
- Diff: `lazygit`, with a git-status fallback
- DB window: on by default as a plain shell
- DB client: off unless using `full`, `heavy`, `db`, or `--db`

Runner detection:

1. `package.json`: `npm run dev`
2. `go.mod`: `go run .`
3. `Makefile`: `make`

When `.nvmrc` exists, runner panes source `nvm` and run `nvm use --silent` before starting `npm`.

DB client preference:

1. `rainfrog`
2. `pgcli`
3. `psql`

`DATABASE_URL` is used automatically when it is set.

## Keybindings

```sh
ptx --keys
ptx keys
```

See [docs/KEYBINDINGS.md](docs/KEYBINDINGS.md).

## Bundled Config

- `config/nvim/init.lua`: VS Code Dark+ Neovim with file tree, Telescope file search, `jj`, Go/JS/TS/templ support, and a 120-column guide
- `config/tmux/tmux.conf`: tmux prefix, pane navigation, mouse scrolling, large history, VS Code Dark+ status theme
- `config/tmux/vscode-dark-plus.tmux`: tmux theme
- `config/ghostty/config`: Ghostty VS Code Dark+ palette
