#!/usr/bin/env bash
# Context percentage first: it's the resource that degrades before it runs out.
read -r payload
q() { printf '%s' "$payload" | jq -r "$1 // empty" 2>/dev/null; }

used=$(q '.cost.total_tokens // .context.used_tokens')
win=$(q '.context.max_tokens // .model.context_window')
model=$(q '.model.display_name')
dir=$(basename "$(q '.workspace.current_dir')")

ctx=''
if [ -n "$used" ] && [ -n "$win" ] && [ "$win" -gt 0 ] 2>/dev/null; then
  pct=$(( used * 100 / win ))
  # 70% is where the docs say recall starts slipping
  if   [ "$pct" -ge 85 ]; then ctx=$(printf '\033[31mctx %d%%\033[0m' "$pct")
  elif [ "$pct" -ge 70 ]; then ctx=$(printf '\033[33mctx %d%%\033[0m' "$pct")
  else                         ctx=$(printf '\033[32mctx %d%%\033[0m' "$pct")
  fi
fi

vc=$(jj log -r @ --no-graph -T 'bookmarks.join(",") ++ " " ++ change_id.short(6)' 2>/dev/null) \
  || vc=$(git branch --show-current 2>/dev/null)

printf '%s' "${ctx:+$ctx  }$dir${vc:+  $vc}${model:+  $model}"
