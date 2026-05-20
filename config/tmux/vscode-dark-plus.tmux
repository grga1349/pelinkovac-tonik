#!/usr/bin/env bash

bg="#1e1e1e"
bg_alt="#2d2d30"
fg="#d4d4d4"
blue="#569cd6"
yellow="#dcdcaa"
status_fg="$blue"

get() {
  local option="$1"
  local default_value="$2"
  local value
  value="$(tmux show-option -gqv "$option")"
  if [ -n "$value" ]; then
    printf '%s\n' "$value"
  else
    printf '%s\n' "$default_value"
  fi
}

setg() {
  tmux set-option -gq "$1" "$2"
}

setw() {
  tmux set-window-option -gq "$1" "$2"
}

widgets="$(get "@vscode_dark_plus_widgets" "")"
time_format="$(get "@vscode_dark_plus_time_format" "%R")"
date_format="$(get "@vscode_dark_plus_date_format" "%d/%m")"

setg status on
setg status-justify left
setg status-left-length 80
setg status-right-length 80
setg status-style "fill=$status_fg,fg=$bg,bg=$status_fg"
setg message-style "fg=$fg,bg=$bg_alt"
setg message-command-style "fg=$fg,bg=$bg_alt"
setg pane-border-style "fg=$bg_alt,bg=$bg"
setg pane-active-border-style "fg=$blue,bg=$bg"
setg display-panes-active-colour "$yellow"
setg display-panes-colour "$blue"

setw window-status-separator "#[fg=$bg,bg=$status_fg] "
setw window-style "fg=$fg,bg=$bg"
setw window-active-style "fg=$fg,bg=$bg"
setw window-status-style "fg=$bg,bg=$status_fg"
setw window-status-current-style "fg=$status_fg,bg=$bg,bold"
setw window-status-activity-style "fg=$yellow,bg=$status_fg"

setg status-left "#[fg=$bg,bg=$status_fg,bold] #S #[fg=$bg,bg=$status_fg,nobold] "
setw window-status-format "#[fg=$bg,bg=$status_fg] #I:#W #[fg=$bg,bg=$status_fg]"
setw window-status-current-format "#[fg=$status_fg,bg=$bg,bold] #I:#W #[fg=$bg,bg=$status_fg,nobold]"

if [ -n "$widgets" ]; then
  setg status-right "#[fg=$bg,bg=$status_fg]${widgets} ${time_format} ${date_format}"
else
  setg status-right "#[fg=$bg,bg=$status_fg]${time_format} ${date_format}"
fi
