#!/usr/bin/env bash

bg="#1e1e1e"
bg_alt="#252526"
fg="#d4d4d4"
muted="#858585"
accent="#2472c8"
blue="#2472c8"
yellow="#e5e510"
bar_bg="#2d2d30"

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
setg status-style "fg=$muted,bg=$bar_bg"
tmux set-option -ugq "status-format[0]"
tmux set-option -gq "status-format[0]" "#[fill=$bar_bg]#[align=left range=left #{E:status-left-style}]#[push-default]#{T;=/#{status-left-length}:status-left}#[pop-default]#[norange default]#[list=on align=#{status-justify}]#[list=left-marker]<#[list=right-marker]>#[list=on]#{W:#[range=window|#{window_index} #{E:window-status-style}#{?#{&&:#{window_last_flag},#{!=:#{E:window-status-last-style},default}}, #{E:window-status-last-style},}#{?#{&&:#{window_bell_flag},#{!=:#{E:window-status-bell-style},default}}, #{E:window-status-bell-style},#{?#{&&:#{||:#{window_activity_flag},#{window_silence_flag}},#{!=:#{E:window-status-activity-style},default}}, #{E:window-status-activity-style},}}]#[push-default]#{T:window-status-format}#[pop-default]#[norange default]#{?window_end_flag,,#{window-status-separator}},#[range=window|#{window_index} list=focus #{?#{!=:#{E:window-status-current-style},default},#{E:window-status-current-style},#{E:window-status-style}}#{?#{&&:#{window_last_flag},#{!=:#{E:window-status-last-style},default}}, #{E:window-status-last-style},}#{?#{&&:#{window_bell_flag},#{!=:#{E:window-status-bell-style},default}}, #{E:window-status-bell-style},#{?#{&&:#{||:#{window_activity_flag},#{window_silence_flag}},#{!=:#{E:window-status-activity-style},default}}, #{E:window-status-activity-style},}}]#[push-default]#{T:window-status-current-format}#[pop-default]#[norange list=on default]#{?window_end_flag,,#{window-status-separator}}}#[nolist align=right range=right #{E:status-right-style}]#[push-default]#{T;=/#{status-right-length}:status-right}#[pop-default]#[norange default]"
setg message-style "fg=$fg,bg=$bar_bg,bold"
setg message-command-style "fg=$fg,bg=$bar_bg"
setg pane-border-style "fg=$bg_alt,bg=$bg"
setg pane-active-border-style "fg=$accent,bg=$bg"
setg display-panes-active-colour "$accent"
setg display-panes-colour "$muted"

setw window-status-separator "#[fg=$muted,bg=$bar_bg] "
setw window-style "fg=$fg,bg=$bg"
setw window-active-style "fg=$fg,bg=$bg"
setw window-status-style "fg=$muted,bg=$bar_bg"
setw window-status-current-style "fg=$accent,bg=$bar_bg,bold"
setw window-status-activity-style "fg=$yellow,bg=$bar_bg"

setg status-left "#[fg=$muted,bg=$bar_bg] #S #[fg=$muted,bg=$bar_bg,nobold] "
setw window-status-format "#[fg=$muted,bg=$bar_bg] #I:#W "
setw window-status-current-format "#[fg=$accent,bg=$bar_bg,bold] #I:#W "

if [ -n "$widgets" ]; then
  setg status-right "#[fg=$muted,bg=$bar_bg] ${widgets} ${time_format} ${date_format} "
else
  setg status-right "#[fg=$muted,bg=$bar_bg] ${time_format} ${date_format} "
fi
