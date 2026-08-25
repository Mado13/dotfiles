#!/bin/sh
# PostToolUse: a wakatime heartbeat for the file Claude touched, through the jj wrapper
file=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')
[ -n "$file" ] || exit 0
exec ~/.local/bin/wakatime-jj --entity "$file" --plugin "claude-code/hook"
