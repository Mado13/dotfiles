#!/usr/bin/env python3
"""Stop hook, async: run the specs that cover this change, in the background.

Blocking on tests every turn wrecks the feedback loop, so this one is wired with
asyncRewake. The turn ends immediately; a failure wakes the session back up with
the output. Exit 2 is what triggers that wake.

Per-repo .claude/verify-tests.sh gets the changed files and decides what to run.
"""
import json
import os
import subprocess
import sys

TIMEOUT = 600


def config_dir(root):
    """Per-repo config, keyed on the repo path so nothing lands in the repo itself.
    Same naming as Claude Code's own project dirs. Falls back to in-repo .claude."""
    local = os.path.expanduser('~/.claude-local/' + root.replace('/', '-'))
    return local if os.path.isdir(local) else os.path.join(root, '.claude')


def repo_root():
    d = os.getcwd()
    while True:
        if os.path.isdir(os.path.join(d, '.jj')) or os.path.exists(os.path.join(d, '.git')):
            return d
        parent = os.path.dirname(d)
        if parent == d:
            return None
        d = parent


def changed(root):
    for cmd in (['jj', 'diff', '--name-only'], ['git', 'diff', '--name-only', 'HEAD']):
        try:
            out = subprocess.run(cmd, cwd=root, capture_output=True, text=True, timeout=20)
        except (OSError, subprocess.TimeoutExpired):
            continue
        if out.returncode == 0 and out.stdout.strip():
            return [p for p in out.stdout.split('\n') if p
                    and os.path.isfile(os.path.join(root, p))]
    return []


def main():
    try:
        json.load(sys.stdin)
    except Exception:
        pass

    root = repo_root()
    if not root:
        return 0
    cfg = config_dir(root)
    script = os.path.join(cfg, 'verify-tests.sh')
    if not os.access(script, os.X_OK):
        return 0
    if os.path.exists(os.path.join(cfg, '.verify-off')):
        return 0

    files = changed(root)
    if not files:
        return 0

    try:
        run = subprocess.run([script] + files, cwd=root, capture_output=True,
                             text=True, timeout=TIMEOUT)
    except (OSError, subprocess.TimeoutExpired):
        return 0

    if run.returncode != 0:
        out = ((run.stdout or '') + (run.stderr or '')).strip()
        if len(out) > 8000:
            out = out[:8000] + '\n[truncated]'
        sys.stderr.write('Specs covering this change are failing:\n\n' + out + '\n')
        return 2
    return 0


sys.exit(main())
