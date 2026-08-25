#!/bin/bash
# lsappinfo, not System Events: reading the frontmost app via AppleScript needs
# an Accessibility grant, lsappinfo needs none
set -u

payload=$(cat)
msg=$(printf '%s' "$payload" | jq -r '.message // "waiting for you"')
dir=$(printf '%s' "$payload" | jq -r '.cwd // ""')
proj=${dir##*/}

front=$(lsappinfo info -only bundleid "$(lsappinfo front 2>/dev/null)" 2>/dev/null)
focused=0
case $front in
  *com.mitchellh.ghostty*) focused=1 ;;
esac

if [ "$focused" = 1 ] && [ -n "${TMUX_PANE:-}" ]; then
  vis=$(tmux display -p -t "$TMUX_PANE" \
    '#{&&:#{session_attached},#{&&:#{window_active},#{pane_active}}}' 2>/dev/null)
  [ "$vis" = 1 ] || focused=0
fi

[ "$focused" = 1 ] && exit 0

osascript -e 'on run argv
display notification (item 1 of argv) with title "Claude Code" subtitle (item 2 of argv) sound name "Ping"
end run' "$msg" "${proj:-claude}" >/dev/null 2>&1 || true
