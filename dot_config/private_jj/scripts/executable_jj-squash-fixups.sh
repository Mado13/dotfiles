#!/bin/sh
# Fold every "fixup!" commit into the commit it names, like git rebase --autosquash.
#
#   jj squash-fixups           the stack @ is sitting on, nothing else
#   jj squash-fixups <revset>  a scope you pick, 'mutable()' for the whole repo
#
# A fixup is matched to its target by subject, not by position: "fixup! add foo"
# looks for the nearest ancestor whose subject is "add foo". The target keeps its
# own description and the fixup's is dropped. Anything that can't be matched
# unambiguously is reported and left alone.
set -eu

# mutable() would be every fetched branch in the repo, other people's fixups included
scope=${1:-'trunk()..(::@ | @::)'}

# newline separated, so $() trims cleanly and a single result has no stray padding
ids() { jj log --no-graph -r "$1" -T 'change_id.short() ++ "\n"'; }
count() { set -- $1; echo $#; }

fixups=$(ids '('"$scope"') & subject(glob:"fixup! *")')
if [ -z "$fixups" ]; then
  echo "no fixup commits found"
  exit 0
fi

# resolve every fixup to a target up front, the graph shifts once we start squashing
pairs=
for f in $fixups; do
  subject=$(jj log --no-graph -r "$f" -T 'description.first_line()')
  # "fixup! fixup! add foo" still belongs to "add foo"
  while [ "$subject" != "${subject#fixup! }" ]; do subject=${subject#fixup! }; done
  if [ -z "$subject" ]; then
    echo "$f: bare \"fixup!\" with no subject, skipping" >&2
    continue
  fi

  quoted=$(printf '%s' "$subject" | sed 's/[\\"]/\\&/g')
  target=$(ids 'heads(::'"$f"'- & subject(exact:"'"$quoted"'"))')
  n=$(count "$target")
  if [ "$n" -eq 0 ]; then
    echo "$f: no ancestor with subject \"$subject\", skipping" >&2
    continue
  fi
  if [ "$n" -gt 1 ]; then
    echo "$f: subject \"$subject\" is ambiguous ($(echo $target)), skipping" >&2
    continue
  fi
  frozen=$(ids '('"$target"') & immutable()')
  if [ -n "$frozen" ]; then
    echo "$f: target \"$subject\" is immutable, skipping" >&2
    continue
  fi
  pairs="$pairs $target:$f"
done

if [ -z "$pairs" ]; then
  echo "no fixup commits to squash"
  exit 0
fi

# @ parked on a fixup would get stranded on a fork once that commit goes away
here=$(ids '@')
for p in $pairs; do
  case $p in
    *:"$here") jj edit -r "${p%%:*}"; break ;;
  esac
done

# one squash per target, so several fixups on one commit merge in a single step
for t in $(printf '%s\n' $pairs | cut -d: -f1 | sort -u); do
  from=$(printf '%s\n' $pairs | grep "^$t:" | cut -d: -f2 | tr '\n' '|' | sed 's/|$//')
  if [ -z "$from" ]; then
    echo "squash-fixups: lost the fixups for $t, stopping" >&2
    exit 1
  fi
  content=$(ids '('"$from"') & ~empty()')
  if [ -n "$content" ]; then
    jj squash --use-destination-message --from "$from" --into "$t"
  else
    # nothing to move, these fixups never got content
    jj abandon $(printf '%s' "$from" | tr '|' ' ')
  fi
done
