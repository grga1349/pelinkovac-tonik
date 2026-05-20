#!/usr/bin/env bash

bg="#1e1e1e"
bg_alt="#2d2d30"
active_tab="#000000"
fg="#d4d4d4"
blue="#569cd6"
yellow="#dcdcaa"

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
setg status-style "fg=$fg,bg=$bg"
setg message-style "fg=$fg,bg=$bg_alt"
setg message-command-style "fg=$fg,bg=$bg_alt"
setg pane-border-style "fg=$bg_alt,bg=$bg"
setg pane-active-border-style "fg=$blue,bg=$bg"
setg display-panes-active-colour "$yellow"
setg display-panes-colour "$blue"

setw window-status-separator " "
setw window-style "fg=$fg,bg=$bg"
setw window-active-style "fg=$fg,bg=$bg"
setw window-status-style "fg=$fg,bg=$bg"
setw window-status-current-style "fg=$fg,bg=$active_tab,bold"
setw window-status-activity-style "fg=$yellow,bg=$bg"

setg status-left "#[fg=$fg,bg=$bg,bold] #S #[fg=$fg,bg=$bg,nobold] "
setw window-status-format "#[fg=$fg,bg=$bg] #I:#W "
setw window-status-current-format "#[fg=$fg,bg=$active_tab,bold] #I:#W "

if [ -n "$widgets" ]; then
  setg status-right "#[fg=$fg,bg=$bg]${widgets} ${time_format} ${date_format}"
else
  setg status-right "#[fg=$fg,bg=$bg]${time_format} ${date_format}"
fi
