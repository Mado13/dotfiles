#!/usr/bin/env python3
"""PreToolUse Bash hook: refuse a playwright-cli browser that isn't firefox."""
import json
import re
import shlex
import sys

WRAPPERS = {'sudo', 'time', 'command', 'builtin', 'nohup', 'nice', 'env'}
ASSIGNMENT = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*=')
LAUNCHES = {'open'}


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


def parse(args):
    """Return (subcommand, --browser value). Either may be None."""
    sub = None
    browser = None
    i = 0
    while i < len(args):
        a = args[i]
        if a.startswith('--browser='):
            browser = a.split('=', 1)[1]
        elif a == '--browser' and i + 1 < len(args):
            browser = args[i + 1]
            i += 1
        elif not a.startswith('-') and sub is None:
            sub = a
        i += 1
    return sub, browser


def check(head, args):
    if head != 'playwright-cli':
        return None
    sub, browser = parse(args)
    if sub not in LAUNCHES:
        return None
    if browser is None:
        return ('playwright-cli open needs --browser firefox. Firefox is the browser for '
                'every session on this machine, so a default-chromium open is wrong even '
                'when the page renders fine.')
    if browser.lower() != 'firefox':
        return (f'--browser {browser} is not firefox. Rerun with --browser firefox.')
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
    for part in re.split(r'\|\||&&|;|\||\n', cmd):
        toks = head_tokens(part.strip())
        if not toks:
            continue
        reason = check(toks[0].rsplit('/', 1)[-1], toks[1:])
        if reason and reason not in reasons:
            reasons.append(reason)

    if reasons:
        body = '\n\n'.join('- ' + r for r in reasons)
        print(json.dumps({'hookSpecificOutput': {
            'hookEventName': 'PreToolUse',
            'permissionDecision': 'deny',
            'permissionDecisionReason': (
                'Blocked by the browser-rules hook.\n\n' + body +
                '\n\nIf a page genuinely only works in another engine, append "# force".')}}))


main()
