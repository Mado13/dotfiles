#!/usr/bin/env python3
"""Stop hook: run the repo's own check before the turn can end.

Generic on purpose. The commands live in each repo's .claude/verify.sh, which
gets the changed files as arguments. No verify.sh means no gate.
"""
import json
import os
import subprocess
import sys

TIMEOUT = 120


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
            # jj lists deleted paths too, and a linter errors on those
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
        return
    cfg = config_dir(root)
    script = os.path.join(cfg, 'verify.sh')
    if not os.access(script, os.X_OK):
        return
    if os.path.exists(os.path.join(cfg, '.verify-off')):
        return

    files = changed(root)
    if not files:
        return

    try:
        run = subprocess.run([script] + files, cwd=root, capture_output=True,
                             text=True, timeout=TIMEOUT)
    except subprocess.TimeoutExpired:
        print(json.dumps({'systemMessage': 'verify.sh timed out, gate skipped'}))
        return
    except OSError as e:
        print(json.dumps({'systemMessage': 'verify.sh could not run: {}'.format(e)}))
        return

    if run.returncode != 0:
        out = ((run.stdout or '') + (run.stderr or '')).strip()
        if len(out) > 6000:
            out = out[:6000] + '\n[truncated]'
        print(json.dumps({
            'decision': 'block',
            'reason': ('.claude/verify.sh failed, so the work is not done. Fix these, '
                       'then say what you fixed.\n\n' + out)}))


main()
