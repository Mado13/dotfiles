#!/bin/sh
# Create a "fixup!" commit sitting directly on top of its target.
#
#   jj fixup        target is @ (or @- when @ is a fresh empty working copy)
#   jj fixup <rev>  target is <rev>
#
# Fixing up a fixup reuses the same "fixup! <subject>" line rather than
# nesting it, so a whole pile of fixups still points at one real commit.
# jj squash-fixups folds them back in.
set -eu

target=${1:-}
if [ -z "$target" ]; then
  # nothing to fix up in an empty undescribed working copy, aim at its parent
  state=$(jj log --no-graph -r @ -T 'if(description, "d", "-") ++ if(empty, "e", "-")')
  [ "$state" = "-e" ] && target='@-' || target='@'
fi

n=$(jj log --no-graph -r "$target" -T '"x\n"' | grep -c . || true)
if [ "$n" -ne 1 ]; then
  echo "fixup: '$target' matches $n commits, need exactly one" >&2
  exit 1
fi

if [ -n "$(jj log --no-graph -r "($target) & immutable()" -T '"x"')" ]; then
  echo "fixup: '$target' is immutable, a fixup on it could never be squashed back" >&2
  exit 1
fi

subject=$(jj log --no-graph -r "$target" -T 'description.first_line()')
if [ -z "$subject" ]; then
  echo "fixup: '$target' has no description, nothing to point a fixup at" >&2
  exit 1
fi

case "$subject" in
  'fixup! '*) msg=$subject ;;
  *) msg="fixup! $subject" ;;
esac

jj new --insert-after "$target" -m "$msg"
