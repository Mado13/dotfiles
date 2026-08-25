#!/usr/bin/env python3
"""PreToolUse Bash hook: refuse the slow shape of a search, read, or in-place edit."""
import json
import re
import shlex
import sys

WRAPPERS = {'sudo', 'time', 'command', 'builtin', 'nohup', 'nice', 'xargs', 'env'}
ASSIGNMENT = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*=')
RG_BOOL = set('nlicwvusSHNopqzah')


def head_tokens(segment):
    try:
        toks = shlex.split(segment)
    except ValueError:
        toks = segment.split()
    while toks:
        first = toks[0]
        if ASSIGNMENT.match(first) or first.rsplit('/', 1)[-1] in WRAPPERS:
            toks = toks[1:]
        else:
            break
    return toks


def check(head, args, seg, piped_in):
    flags = [a for a in args if a.startswith('-')]
    operands = [a for a in args if not a.startswith('-')]

    if head == 'cd':
        return ('cd makes every path after it unresolvable, so any Read deny rule in scope '
                'turns the command into a permission prompt. Drop the cd, pass absolute '
                'paths, or use the tool flag: rg PATH, fd PATTERN PATH, git -C, jj -R, '
                'pnpm --dir.')

    if head == 'rg':
        for flag in flags:
            if flag.startswith('--') or len(flag) < 3 or 'r' not in flag[1:]:
                continue
            if set(flag[1:]) <= RG_BOOL | {'r'}:
                return ('rg -r is --replace, not recursive, and rg recurses by default. A '
                        'bundle like -rn rewrites every match to "n". Drop the r.')

    if head in ('grep', 'egrep', 'fgrep') and not piped_in:
        return ('grep is reading files here. Measured on this repo: 30.7s for grep vs '
                '0.64s for rg on log/test.log. Rerun with rg, same pattern and paths. '
                'rg -uu reaches gitignored paths like log/, -m N stops early, -c counts only.')

    if head == 'find' and not piped_in:
        return ('find is slow and ignores .gitignore. Use fd (fd PATTERN [path], -e rb for '
                'an extension, -t f for files only, -H -I to include hidden and ignored) '
                'or the Glob tool.')

    if head == 'cat' and operands and '<<' not in seg and '>' not in seg:
        return ('cat has no line numbers, so you cannot cite file:line and end up reading '
                'twice. Use the Read tool (offset/limit for a slice). To search the file, '
                'rg PATTERN FILE.')

    if head == 'sed' and any(f == '-i' or f.startswith('--in-place') or
                             (not f.startswith('--') and 'i' in f[1:]) for f in flags):
        return ('sed -i edits in place and the change never appears in the transcript. Use '
                'the Edit tool, or sd PATTERN REPLACEMENT FILE for a bulk rewrite.')

    if head in ('cloc', 'wc') and '-l' in flags and len(operands) > 3:
        return 'Use tokei to size a codebase instead of counting lines across many files.'

    return None


def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return
    if payload.get('tool_name') != 'Bash':
        return
    cmd = (payload.get('tool_input') or {}).get('command') or ''
    if '# force' in cmd:
        return

    reasons = []
    parts = re.split(r'(\|\||&&|;|\||\n)', cmd)
    prev_sep = None
    for i, part in enumerate(parts):
        if i % 2:
            prev_sep = part
            continue
        seg = part.strip()
        if not seg:
            continue
        toks = head_tokens(seg)
        if not toks:
            continue
        reason = check(toks[0].rsplit('/', 1)[-1], toks[1:], seg, prev_sep == '|')
        if reason and reason not in reasons:
            reasons.append(reason)

    if reasons:
        body = '\n\n'.join('- ' + r for r in reasons)
        print(json.dumps({'hookSpecificOutput': {
            'hookEventName': 'PreToolUse',
            'permissionDecision': 'deny',
            'permissionDecisionReason': (
                'Blocked by the fast-tools hook.\n\n' + body +
                '\n\nIf this exact command is genuinely the right call, append "# force".')}}))


main()
