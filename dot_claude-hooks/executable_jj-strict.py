#!/usr/bin/env python3
"""PreToolUse Bash hook: in a jj-colocated repo, mutating git costs you jj undo."""
import json
import os
import re
import shlex
import sys

WRAPPERS = {'sudo', 'time', 'command', 'builtin', 'nohup', 'nice', 'env'}
ASSIGNMENT = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*=')

JJ = {
    'commit': 'jj describe -m "..." then jj new',
    'checkout': 'jj new -r <rev>, or jj edit -r <rev> to work on it in place',
    'switch': 'jj edit -r <rev>',
    'stash': 'jj new (the working copy is already a commit, nothing to stash)',
    'rebase': 'jj rebase -d <dest>. To fix a commit mid-stack: jj new -A <commit>, '
              'edit, jj describe -m "fixup: ...". jj rebases the descendants for you.',
    'reset': 'jj squash, or jj abandon to drop a change',
    'merge': 'jj new <rev1> <rev2>',
    'cherry-pick': 'jj duplicate -r <rev> --onto <dest>',
    'revert': 'jj revert -r <rev>',
    'restore': 'jj restore -c <rev>',
    'am': 'jj git import after applying, or build the change with jj new',
    'gc': 'jj util gc',
    'filter-branch': 'jj is the wrong place for this. Do it deliberately, outside a session.',
    'push': 'jj bookmark set <name> -r @- then jj git push, and only when asked',
}
READ_ONLY = {'log', 'diff', 'show', 'status', 'ls-files', 'ls-tree', 'blame', 'shortlog',
             'rev-parse', 'rev-list', 'cat-file', 'describe', 'name-rev', 'worktree',
             'apply', 'fetch', 'remote', 'config', 'grep', 'bisect', 'stripspace', 'var'}


def colocated():
    d = os.getcwd()
    while True:
        if os.path.isdir(os.path.join(d, '.jj')):
            return os.path.isdir(os.path.join(d, '.git')) or os.path.isfile(os.path.join(d, '.git'))
        parent = os.path.dirname(d)
        if parent == d:
            return False
        d = parent


def subcommand(seg):
    try:
        toks = shlex.split(seg)
    except ValueError:
        toks = seg.split()
    while toks:
        if ASSIGNMENT.match(toks[0]) or toks[0].rsplit('/', 1)[-1] in WRAPPERS:
            toks = toks[1:]
        else:
            break
    if not toks or toks[0].rsplit('/', 1)[-1] != 'git':
        return None
    words = [t for t in toks[1:] if not t.startswith('-')]
    if not words:
        return None
    # `git stash list` and `git branch --list` only read; their bare forms rewrite
    if len(words) > 1 and words[1] in ('list', 'show'):
        return None
    return words[0]


def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return
    if payload.get('tool_name') != 'Bash':
        return
    cmd = (payload.get('tool_input') or {}).get('command') or ''
    if '# force' in cmd or not colocated():
        return

    hits = []
    for seg in re.split(r'\|\||&&|;|\||\n', cmd):
        sub = subcommand(seg.strip())
        if sub and sub not in READ_ONLY and sub in JJ and sub not in [h[0] for h in hits]:
            hits.append((sub, JJ[sub]))

    if hits:
        body = '\n'.join('- git {}  ->  {}'.format(s, j) for s, j in hits)
        print(json.dumps({'hookSpecificOutput': {
            'hookEventName': 'PreToolUse',
            'permissionDecision': 'deny',
            'permissionDecisionReason': (
                'This repo is jj-colocated. Mutating git here is recoverable but it is '
                'invisible to the jj operation log, so jj undo can no longer walk it back.'
                '\n\n' + body +
                '\n\nRead-only git is fine. If a git command really is the right call, '
                'append "# force" and run jj git import afterwards.')}}))


main()
