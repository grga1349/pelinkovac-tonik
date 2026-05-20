# ptx / pelinkovac-tonik

`ptx` is a small Bash CLI facade for launching tmux dev workspaces.

It detects the current git repo, names the tmux session after the repo folder, attaches to an existing session when one exists, and otherwise creates a ready-to-work layout with shell, work, diff, editor, and DB windows. By default AI, runner, and DB panes are present as shells and do not start commands.

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
ptx           # default workspace with shell, work, diff, edit, db shell
ptx short     # shell + editor only
ptx full      # default + running db client
ptx heavy     # default + two runner panes + running db client
ptx ai        # codex + claude mode
ptx run2      # two runner mode
ptx db        # default + running db client
ptx light     # default layout without DB tab
```

Fun aliases:

```sh
ptx dry       # short
ptx classic   # legacy default with Codex pane and one runner
ptx strong    # full
ptx double    # heavy
ptx lighter   # light
ptx neat      # term + edit, no AI, no runner
```

## Options

```sh
--ai codex|claude|both|none
--runner none|one|two
--db           # create db window and start a db client
--no-db        # skip db window
--editor nvim|hx|none
--diff diffnav|lazygit|delta|none
--reset
--kill
--keys
```

## Layouts

Default:

1. `shell`: home shell + repo shell
2. `work`: AI shell + runner shell
3. `diff`: diffnav
4. `edit`: editor
5. `db`: shell only

Classic:

1. `shell`: home shell + repo shell
2. `work`: AI shell + runner shell
3. `diff`: diffnav
4. `edit`: editor
5. `db`: shell only

Heavy:

1. `shell`
2. `work`: AI shell + runner shell
3. `run`: runner + runner2
4. `diff`
5. `edit`
6. `db`

Light:

1. `shell`: home shell + repo shell
2. `work`: AI shell + runner shell
3. `diff`: diffnav
4. `edit`: editor

## Defaults

- Editor: `nvim`
- AI: one AI pane is created but not launched
- Runner: one runner shell is created but the runner command is not launched
- Diff: `diffnav`
- DB window: on by default as a plain shell
- DB client: off unless using `full`, `heavy`, `db`, or `--db`

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
