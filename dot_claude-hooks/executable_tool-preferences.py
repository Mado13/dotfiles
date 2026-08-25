#!/usr/bin/env python3
"""Re-inject tool preferences at session start and after compaction, where CLAUDE.md rules get lost."""
import json
import sys

CONTEXT = """Tool preferences on this machine, enforced by the fast-tools PreToolUse hook:
- search text: rg, never bash grep. rg -uu reaches gitignored paths (log/, tmp/).
- find files: fd, or the Glob tool. Never bash find.
- read a file: the Read tool with offset/limit. Never cat, and prefer it over sed -n.
- edit a file: the Edit tool, or sd PATTERN REPL FILE for a bulk rewrite. Never sed -i.
- match code structure in Ruby or JS: ast-grep -p 'PATTERN' -l rb, not a regex.
- size a codebase: tokei. Non-code files (PDF, docx, archives): rga. JSON: jq.
log/test.log and log/development.log run to hundreds of MB. Truncate before a spec run
(> log/test.log) instead of scanning the whole file.

Browser work, enforced by the browser-rules PreToolUse hook and a permissions deny:
- Never claude-in-chrome. Its mcp__claude-in-chrome__* tools are denied outright. It
  costs far more tokens: page reads and screenshots land in context, and its tool
  schemas sit in every request whether or not a browser is involved.
- Always playwright-cli, always firefox: playwright-cli -s=<app> open --browser firefox.
  Snapshots go to .playwright-cli/ on disk, so you read only the refs you asked for.
- Any other --browser value is refused, as is an open with no --browser at all.
- Snapshot first to get refs, then act on the refs. The playwright-cli skill has the rest."""

event = sys.argv[1] if len(sys.argv) > 1 else 'SessionStart'
print(json.dumps({'hookSpecificOutput': {'hookEventName': event, 'additionalContext': CONTEXT}}))
