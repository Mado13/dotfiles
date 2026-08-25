#!/usr/bin/env python3
"""PostToolUse hook: hand over the skill that governs the file just edited.

A skill only loads when the model judges it relevant, which is the weak link.
This makes delivery deterministic: touch app/serializers/*, get the serializer
rules, whether or not anyone thought to ask for them.

Per-repo map in .claude/path-rules.json: {"app/serializers/*": "alba-serializers"}
Injected once per skill per session, so a run of edits doesn't repeat it.
"""
import fnmatch
import hashlib
import json
import os
import sys
import tempfile

def config_dir(root):
    """Per-repo config, keyed on the repo path so nothing lands in the repo itself.
    Same naming as Claude Code's own project dirs. Falls back to in-repo .claude."""
    local = os.path.expanduser('~/.claude-local/' + root.replace('/', '-'))
    return local if os.path.isdir(local) else os.path.join(root, '.claude')


def repo_root(start):
    d = start
    while True:
        if os.path.isdir(os.path.join(d, '.jj')) or os.path.exists(os.path.join(d, '.git')):
            return d
        parent = os.path.dirname(d)
        if parent == d:
            return None
        d = parent


def body(path):
    text = open(path, encoding='utf-8').read()
    if text.startswith('---'):
        end = text.find('\n---', 3)
        if end != -1:
            text = text[end + 4:]
    return text.strip()


def already_sent(session, root, skill):
    key = hashlib.sha1('{}|{}|{}'.format(session, root, skill).encode()).hexdigest()
    marker = os.path.join(tempfile.gettempdir(), 'cc-path-rules-' + key)
    if os.path.exists(marker):
        return True
    try:
        open(marker, 'w').close()
    except OSError:
        pass
    return False


def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return
    fp = (payload.get('tool_input') or {}).get('file_path')
    if not fp:
        return
    fp = os.path.abspath(fp)
    root = repo_root(os.path.dirname(fp))
    if not root:
        return

    base = config_dir(root)
    cfg = os.path.join(base, 'path-rules.json')
    if not os.path.isfile(cfg):
        return
    try:
        rules = json.load(open(cfg))
    except (OSError, ValueError):
        return

    rel = os.path.relpath(fp, root)
    session = payload.get('session_id', '')
    chunks = []
    for pattern, skill in rules.items():
        if not fnmatch.fnmatch(rel, pattern):
            continue
        skill_file = os.path.join(base, 'skills', skill, 'SKILL.md')
        if not os.path.isfile(skill_file) or already_sent(session, root, skill):
            continue
        try:
            chunks.append('Rules for {} (from the {} skill):\n\n{}'.format(
                pattern, skill, body(skill_file)))
        except OSError:
            pass

    if chunks:
        print(json.dumps({'hookSpecificOutput': {
            'hookEventName': 'PostToolUse',
            'additionalContext': '\n\n'.join(chunks)}}))


main()
