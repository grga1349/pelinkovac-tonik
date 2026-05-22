# ptx Keybindings

## tmux

- Prefix: `Ctrl-j`
- Send prefix: `Ctrl-j Ctrl-j`
- Split right: `Ctrl-j |`
- Split down: `Ctrl-j _`
- Previous/next window: `Alt-h`, `Alt-l`
- Move panes left/right: `Alt-j`, `Alt-k`
- Select windows: `Alt-1` through `Alt-6`
- Resize panes: `Ctrl-j Ctrl-h`, `Ctrl-j Ctrl-j`, `Ctrl-j Ctrl-k`, `Ctrl-j Ctrl-l`
- Mouse scroll: enabled
- Shift-Enter: sends a literal line feed for multiline input in Codex and Claude

## Neovim

- Escape insert mode: `jj`
- File tree: `Space e`
- File finder: `Ctrl-p`, `Space f f`, `Space p`
- Text search: `Space /`, `Space f g`
- Buffers: `Space f b`
- Help tags: `Space f h`
- Save: `Space w`
- Quit: `Space q`
- Go to definition: `g d`
- References: `g r`
- Hover: `K`
- Rename: `Space r n`
- Code action: `Space c a`
- Format: `Space f`
- AI Notes panel: `Space a`
- AI Notes visual note: `Space a` in visual mode (attaches selected code)
- AI Notes prompt review: `Space A`
  - `Tab` switch between write and list panes
  - `CR` write pane: save note / list pane: jump to file
  - `e` edit note, `d` delete note, `D` clear all
  - `a` add note from source window cursor
  - `gp` open prompt review float (edit then `CR` to copy)
  - `gy` copy prompt to clipboard directly
  - `r` refresh list, `q` close modal

## rainfrog

- Cycle panes forward: `Alt-]`, `Tab`
- Cycle panes backward: `Alt-[`, `Shift-Tab`
- Jump to editor: `Alt-\`
- Execute query: `Ctrl-Enter`
- Execute query (bypass parser): `Alt-Enter`
- Abort query: `q` (menu/results/history/favorites)
- Quit: `Ctrl-c`

## ptx

- Show help: `ptx help`, `ptx --help`
- Show this cheatsheet: `ptx keys`, `ptx --keys`
- Recreate current repo session: `ptx --reset`
- Kill current repo session: `ptx --kill`
