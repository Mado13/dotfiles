#!/usr/bin/env sh
set -u
bookmark=$(jj log --no-graph -r 'heads(::@ & bookmarks() ~ trunk())' \
  -T 'bookmarks.map(|b| b.name()).join(",")')
bookmark=${bookmark%%,*} # take first if multiple
[ -z "$bookmark" ] && exit 0
sha=$(jj log --no-graph -r "$bookmark" -T 'commit_id')
project=$(git remote get-url origin | sed -E 's#.*[:/]([^/]+)/([^/]+)\.git#gh/\1/\2#')

# supersede any previous watcher for this branch
safe=$(echo "$bookmark" | tr '/ ' '__')
pidfile="/tmp/ci-watch-$safe.pid"
[ -f "$pidfile" ] && kill "$(cat "$pidfile")" 2>/dev/null
echo $$ >"$pidfile"

circleci run watch --project "$project" --sha "$sha" >/dev/null 2>&1
result=$?
rm -f "$pidfile"

case "$result" in
  0) osascript -e "display notification \"$bookmark passed\" with title \"CircleCI\" sound name \"Glass\"" ;;
  6) osascript -e "display notification \"$bookmark cancelled\" with title \"CircleCI\" sound name \"Funk\"" ;;
  8) osascript -e "display notification \"$bookmark timed out\" with title \"CircleCI\" sound name \"Funk\"" ;;
  *) osascript -e "display notification \"$bookmark failed — run cifail\" with title \"CircleCI\" sound name \"Basso\"" ;;
esac
