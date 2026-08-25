#!/usr/bin/env python3
"""Catches AI tells in text written as Matan. The banned words live only here:
~/.claude-shared/voice.md leaves them out on purpose, since naming them in a
prompt primes them.

Three events, one script:
  Stop         scans comments added in the working diff
  PreToolUse   scans commit/PR/comment text in a Bash command before it runs
  PostToolUse  scans comment smells in a file just written

Only comment text is checked in diffs, never code, so a variable named
`landscape` or a fixture string won't trip it.

jj first, git as fallback. `git diff HEAD` returns nothing in a jj-only repo,
which is what made the previous version of this hook a no-op there.

Warn-only: change both `sys.exit(2)` to `sys.exit(0)`.
"""

import json
import os
import re
import subprocess
import sys

WORDS = [
    "delve", "delves", "delving", "leverage", "leverages", "leveraging",
    "utilize", "utilizes", "utilizing", "utilization", "robust",
    "comprehensive", "seamless", "seamlessly", "streamline", "streamlines",
    "streamlined", "foster", "fosters", "holistic", "crucial", "pivotal",
    "showcase", "showcases", "underscore", "underscores", "nuanced",
    "facilitate", "facilitates", "myriad", "realm", "landscape", "testament",
    "tapestry", "elevate", "elevates", "unlock", "unlocks", "empower",
    "empowers", "thereby", "moreover", "furthermore",
    # tier 1/2 tells from the AI-patterns research
    "intricate", "intricacies", "meticulous", "meticulously", "multifaceted",
    "embark", "spearhead", "spearheaded", "bolster", "bolstered", "garner",
    "garnered", "labyrinth", "symphony", "vibrant", "resonate", "resonates",
    "illuminate", "illuminates", "enduring", "innovative", "cutting-edge",
    "game-changer", "additionally", "consequently", "nevertheless",
    "subsequently", "nonetheless",
    # deliberately NOT here: navigate, dynamic, enhance, interplay.
    # they're load-bearing words in a Svelte/Rails codebase.
]

PHRASES = [
    r"it'?s worth noting", r"this ensures that", r"in order to", r"note that",
    r"when it comes to", r"at the end of the day", r"dive into",
    r"let'?s explore", r"not only .{1,40} but", r"isn'?t just .{1,40}, it'?s",
    r"is not just .{1,40}, it'?s", r"great question", r"excellent point",
    r"you'?re absolutely right", r"happy to help", r"hope this helps",
    r"let me know if you have any questions", r"here'?s the thing",
    r"let'?s (break this down|unpack)", r"in conclusion", r"in summary",
    r"generally speaking", r"it could be argued", r"to some extent",
]

WORD_RE = re.compile(r"\b(" + "|".join(WORDS) + r")\b", re.I)
PHRASE_RE = re.compile("|".join(PHRASES), re.I)
# "ensure" the verb, not a symbol like ensureLoaded
ENSURE_RE = re.compile(r"\bensures?\b(?![A-Za-z_])", re.I)
SENTENCES = re.compile(r"(?<=[.!?])\s+")
MAX_WORDS = 30
EM_DASH = "—"


def reasons_for(text):
    out = []
    for m in WORD_RE.finditer(text):
        out.append('banned word "%s"' % m.group(1))
    for m in PHRASE_RE.finditer(text):
        out.append('banned phrase "%s"' % m.group(0).strip())
    if ENSURE_RE.search(text):
        out.append('"ensure", use "make sure"')
    if EM_DASH in text:
        out.append("em dash")
    # Per line, else a bulleted commit message reads as one giant sentence.
    for line in text.splitlines():
        for s in SENTENCES.split(line):
            n = len(s.split())
            if n > MAX_WORDS:
                out.append("%d-word sentence, split it" % n)
    seen, uniq = set(), []
    for r in out:
        if r.lower() not in seen:
            seen.add(r.lower())
            uniq.append(r)
    return uniq


# --- Stop: comments in the working diff ---------------------------------------

SKIP_EXT = (".lock", ".json", ".csv", ".svg", ".map", ".po", ".pot", ".min.js")

# Openers have to be per language. `#` opens a comment in Ruby and starts a
# private method in JS, so one shared pattern read `#expand () {` as a comment.
HASH, SLASH, DASH, DOCSTR = r"\#+", r"//+|/\*+|\*+(?!/)", r"--+", r"\"\"\"|'''"
EXT_OPENERS = {
    ".rb": (HASH,), ".rake": (HASH,), ".gemspec": (HASH,), ".erb": (HASH,),
    ".py": (HASH, DOCSTR), ".sh": (HASH,), ".fish": (HASH,),
    ".yml": (HASH,), ".yaml": (HASH,), ".ex": (HASH,), ".exs": (HASH,),
    ".js": (SLASH,), ".jsx": (SLASH,), ".ts": (SLASH,), ".tsx": (SLASH,),
    ".svelte": (SLASH,), ".scss": (SLASH,), ".css": (SLASH,), ".slim": (SLASH,),
    ".rs": (SLASH,), ".go": (SLASH,), ".lua": (DASH,), ".sql": (DASH,),
}
DEFAULT_OPENERS = (HASH, SLASH)
_RE_CACHE = {}


def whole_line_re(path):
    ext = os.path.splitext(path.lower())[1]
    openers = EXT_OPENERS.get(ext, DEFAULT_OPENERS)
    if openers not in _RE_CACHE:
        _RE_CACHE[openers] = re.compile(
            r"^\s*(?:%s|<!--)\s*(.*?)\s*(?:\*/|-->)?\s*$" % "|".join(openers))
    return _RE_CACHE[openers]


TRAILING = re.compile(r"(?:(?<!:)//+|\s\#)\s*(.+?)\s*$")


def working_diff():
    for cmd in (["jj", "diff", "--git"], ["git", "diff", "HEAD"]):
        try:
            p = subprocess.run(cmd, capture_output=True, text=True, timeout=20)
        except (OSError, subprocess.SubprocessError):
            continue
        if p.returncode == 0 and p.stdout.strip():
            return p.stdout
    return ""


def added_comments(diff):
    """Yields (path, text, opens_block). Only a block's first line is a sentence start."""
    path, prev = "?", False
    for line in diff.splitlines():
        cur = False
        if line.startswith("+++ "):
            path = line[4:].strip()
            path = path[2:] if path.startswith("b/") else path
        elif line.startswith("+") and not line.startswith("+++"):
            body = line[1:]
            m, whole = None, False
            if not path.lower().endswith(SKIP_EXT):
                m = whole_line_re(path).match(body)
                whole = bool(m)
                m = m or TRAILING.search(body)
            if m and m.group(1):
                cur = whole
                yield path, m.group(1), not (prev and whole)
        prev = cur


# --- PostToolUse: comment smells in what was just written ---------------------

CODE_EXT = (".rb", ".js", ".jsx", ".ts", ".tsx", ".svelte", ".py", ".lua", ".rs",
            ".go", ".ex", ".exs", ".slim", ".erb", ".scss", ".css", ".sh", ".fish")
STOPWORDS = frozenset("""a an the of to for in on at by is are was be this that it its
and or if we so but from with as all not no do does then than there here when""".split())
# history belongs in git log. Narrow on purpose, a bare "was" is too common.
HISTORY = re.compile(
    r"\b(previously|used to|formerly|migrated from|renamed from|replaced by|"
    r"ported from|no longer needed|this used|which used)\b", re.I)
# "Preferences was UserDefaults" is history, "the index was not ready" is a why.
# Requiring a CamelCase word after was/were separates them: a former type or
# library gets named, a state description does not.
WAS_A_THING = re.compile(r"\b(?:was|were)\s+(?:a|an|the)?\s*[A-Z][a-z]\w*")
BEAUTIFY = re.compile(r"^[-=*_~#]{4,}$")
# Needs code-like syntax after the keyword, not just the word. "for Stimulus
# best practices" and "for which the libraries..." are prose, not code.
COMMENTED_CODE = re.compile(
    r"^(?:if|for|while|switch)\s*\("
    r"|^(?:const|let|var)\s+[\w$]+\s*="
    r"|^(?:def|function|class)\s+[\w$]+"
    r"|^return\s+\S+;"
    r"|^(?:import|require)\s*[\w({'\"]"
    r"|^end$"
    r"|[;{}]\s*$")
RESTATE_MIN_WORDS = 2
RESTATE_RATIO = 0.6
# Claude opens narration with a capitalised base verb ("Check if", "Send the").
# My own comments are declarative or lowercase. Measured on 196 comments I kept:
# 2 hits, against 24 of 24 samples of the junk.
NARRATION_VERBS = """get set check create return send loop fetch initialize initialise init make
update save delete remove validate call define import iterate add build find load parse convert
handle process render assign store run ensure extract generate clear reset apply start stop open
close read write print log filter sort map count compute calculate determine pass wrap setup
declare configure register mark revoke rescue raise reload retrieve query perform execute invoke
instantiate verify confirm toggle append merge join split trim strip normalize sanitize format
serialize encode decode enqueue dispatch trigger emit notify lookup now""".split()
NARRATION = re.compile(
    r"^(?:%s)\b|^(?:This (?:method|class|function|module|helper|is|will)|We|Let's|Handles?)\b"
    % "|".join(w.capitalize() for w in NARRATION_VERBS))


def words(s):
    """Identifier-aware tokens: parseHours and parse_hours both -> {parse, hours}."""
    s = re.sub(r"([a-z0-9])([A-Z])", r"\1 \2", s)
    return {w for w in re.split(r"[^A-Za-z]+", s.lower()) if w and w not in STOPWORDS}


def comment_smells(body, code):
    """`body` is the comment text, `code` the line it sits above."""
    out = []
    if BEAUTIFY.match(body):
        return ["decorative banner"]
    if HISTORY.search(body) or WAS_A_THING.search(body):
        out.append("history, that is what git log is for")
    if ATTRIBUTION.search(body):
        out.append("attribution, drop it")
    if COMMENTED_CODE.search(body):
        out.append("commented-out code")
    if NARRATION.match(body):
        out.append("narrates the what, say why or delete it")
    cw = words(body)
    if code and len(cw) >= RESTATE_MIN_WORDS:
        shared = cw & words(code)
        if len(shared) / len(cw) >= RESTATE_RATIO:
            out.append("restates the code below it (%s)" % ", ".join(sorted(shared)))
    return out


def commented_lines(text, path):
    """Yield (comment_body, the next real line of code) pairs."""
    wl = whole_line_re(path)
    lines = text.splitlines()
    block, i, n = [], 0, len(lines)
    while i < n:
        m = wl.match(lines[i])
        if m and m.group(1):
            block.append(m.group(1))
            i += 1
            continue
        # A run of comment lines is one comment to the reader, so judge it as
        # one. Line by line, every line of a block got paired with the same
        # code and each was scored on its own fragment.
        if block:
            yield " ".join(block), lines[i] if lines[i].strip() else ""
            block = []
        i += 1
    if block:
        yield " ".join(block), ""


def check_written(payload):
    inp = payload.get("tool_input", {}) or {}
    path = (inp.get("file_path") or "").lower()
    if not path.endswith(CODE_EXT):
        sys.exit(0)
    text = inp.get("content") or inp.get("new_string") or ""
    hits = []
    for body, code in commented_lines(text, path):
        rs = comment_smells(body, code) + reasons_for(body)
        if rs:
            hits.append("  %s\n    %s" % (", ".join(rs), body[:160]))
    if not hits:
        sys.exit(0)
    print("Comment check on %s:" % inp.get("file_path", "?"), file=sys.stderr)
    print("\n".join(hits[:15]), file=sys.stderr)
    print("Delete them unless they pass both tests in ~/.claude-shared/comments.md.",
          file=sys.stderr)
    sys.exit(2)


def check_diff():
    hits = []
    for path, text, opens in added_comments(working_diff()):
        rs = reasons_for(text)
        if opens and NARRATION.match(text):
            rs.append("narrates the what")
        if rs:
            hits.append("  %s: %s\n    %s" % (path, ", ".join(rs), text[:160]))
    if not hits:
        sys.exit(0)
    print("Voice check, these comments don't sound like me:", file=sys.stderr)
    print("\n".join(hits[:25]), file=sys.stderr)
    if len(hits) > 25:
        print("  ... and %d more" % (len(hits) - 25), file=sys.stderr)
    print("Rewrite per ~/.claude-shared/voice.md, then finish.",
          file=sys.stderr)
    sys.exit(2)


# --- PreToolUse: text a Bash command is about to publish ----------------------

# Anchored to the start of a command segment, not just anywhere in the string.
# Unanchored it fired on any script or heredoc that merely quoted a commit,
# which made writing fixtures for this file impossible.
SEGMENT = r"(?:^|[\n;]|&&|\|\|)\s*(?:\w+=\S+\s+)*"
WRITES_TEXT = re.compile(
    SEGMENT + r"(jj\s+(describe|commit|new)|git\s+commit|gh\s+(pr|issue|release)\s+"
    r"(create|edit|comment|review|close)|gh\s+api)\b"
)
# structure rules below are commit-only, a PR body has no 70-char subject
COMMIT_CMD = re.compile(SEGMENT + r"(jj\s+(describe|commit|new)|git\s+commit)\b")
# inline review comments only go out through `gh api .../comments -f body=...`
COMMENT_CMD = re.compile(SEGMENT + r"gh\s+((pr|issue)\s+comment|api)\b")
# `-F "body=..."` is already picked up by QUOTED, so only lowercase -f takes the quoted-key form here
API_BODY = re.compile(
    r"(?:-f|-F|--field|--raw-field)[= ]\s*body=(\"(?:[^\"\\]|\\.)*\"|'[^']*')"
    r"|(?:-f|--field|--raw-field)[= ]\s*(?:\"body=((?:[^\"\\]|\\.)*)\"|'body=([^']*)')")
# p90 of pre-2021 co2m: inline review comment 74 words, conversation 97, commit body 47
COMMENT_MAX_WORDS = 90
COMMIT_BODY_MAX_WORDS = 50
FORCE = re.compile(r"#\s*force\s*$", re.M)
SUBJECT_MAX = 70
# past tense or third person, git itself writes the imperative
NOT_IMPERATIVE = re.compile(
    r"^(Fixed|Fixes|Added|Adds|Updated|Updates|Removed|Removes|Changed|"
    r"Refactored|Implemented|Bumped|Moved|Renamed|Created|Improved)\b"
)
ATTRIBUTION = re.compile(r"Co-authored-by|Generated with|🤖", re.I)


# git requires these literally lowercase for --autosquash, so they are machinery
# and not part of the subject. Without this the hook blocks every fixup commit.
AUTOSQUASH = re.compile(r"^(?:(?:fixup|squash|amend)!\s+)+")


def repo_prefers_lowercase(sample=40):
    """Subject case is per repo, the account CLAUDE.md says which way."""
    tmpl = 'description.first_line() ++ "\n"'
    for cmd in (
        ["jj", "log", "-r", "::@-", "--no-graph", "-n", str(sample), "-T", tmpl],
        ["git", "log", "-n", str(sample), "--format=%s"],
    ):
        try:
            p = subprocess.run(cmd, capture_output=True, text=True, timeout=20)
        except (OSError, subprocess.SubprocessError):
            continue
        if p.returncode != 0:
            continue
        subjects = [s for s in (ln.strip() for ln in p.stdout.splitlines()) if s]
        if subjects:
            return sum(s[:1].islower() for s in subjects) * 2 > len(subjects)
    return False


def structure_reasons(text):
    """Commit message shape, the half a script can check."""
    lines = text.splitlines()
    if not lines:
        return []
    subject, out = AUTOSQUASH.sub("", lines[0]), []
    if len(subject) > SUBJECT_MAX:
        out.append("%d-char subject, keep it under %d" % (len(subject), SUBJECT_MAX))
    if subject.endswith("."):
        out.append("trailing period on the subject")
    if subject[:1].islower() and not repo_prefers_lowercase():
        out.append("subject starts lowercase, capitalize it")
    m = NOT_IMPERATIVE.match(subject)
    if m:
        out.append('"%s" is not imperative' % m.group(1))
    # blank line after the subject, else rebase runs the two together
    if len(lines) > 1 and lines[1].strip():
        out.append("no blank line after the subject")
    if ATTRIBUTION.search(text):
        out.append("AI attribution, drop it")
    return out


def length_reasons(text, kind):
    if kind == "commit":
        n = len(" ".join(text.splitlines()[2:]).split())
        if n > COMMIT_BODY_MAX_WORDS:
            return ["%d-word commit body, one or two lines is the norm" % n]
    if kind == "comment":
        n = len(text.split())
        if n > COMMENT_MAX_WORDS:
            return ["%d-word comment, most here run about 20" % n]
    return []


QUOTED = re.compile(
    r"(?:-m|--message|-t|--title|-b|--body|-F|--body-file)[= ]\s*"
    r"(\"(?:[^\"\\]|\\.)*\"|'[^']*')"
)
HEREDOC = re.compile(r"<<[-~]?['\"]?(\w+)['\"]?\n(.*?)\n\s*\1", re.S)
READS_STDIN = re.compile(
    r"(?:-F|--file|--message-file|-b|--body-file|--body)[= ]*-(?=\s|$)"
    r"|(?:--message-file|--body-file)[= ]\S")


def check_command(cmd):
    if not cmd or not WRITES_TEXT.search(cmd):
        sys.exit(0)
    chunks = [m.group(1)[1:-1] for m in QUOTED.finditer(cmd)]
    # A heredoc is only the message when the command reads the message from
    # stdin or a file. Otherwise it belongs to some unrelated script that
    # merely shares the command line, and scanning it flags Python as prose.
    if READS_STDIN.search(cmd):
        chunks += [m.group(2) for m in HEREDOC.finditer(cmd)]
    for m in API_BODY.finditer(cmd):
        chunks.append(m.group(1)[1:-1] if m.group(1) else (m.group(2) or m.group(3) or ""))
    is_commit = bool(COMMIT_CMD.search(cmd))
    kind = "commit" if is_commit else "comment" if COMMENT_CMD.search(cmd) else None
    hits = []
    for text in chunks:
        rs = reasons_for(text)
        if is_commit:
            rs += structure_reasons(text)
        if not FORCE.search(cmd):
            rs += length_reasons(text, kind)
        if rs:
            hits.append("  %s\n    %s" % (", ".join(rs), text[:200]))
    if not hits:
        sys.exit(0)
    print("Message check, fix these before running it again:", file=sys.stderr)
    print("\n".join(hits), file=sys.stderr)
    print("Voice rules are in ~/.claude-shared/voice.md, commit rules in the repo's CLAUDE.md.",
          file=sys.stderr)
    print("Over a length limit: cut it. Append # force only when I asked for the long version.",
          file=sys.stderr)
    sys.exit(2)


def main():
    try:
        payload = json.loads(sys.stdin.read() or "{}")
    except ValueError:
        payload = {}
    event = payload.get("hook_event_name", "Stop")
    if event == "PreToolUse":
        check_command(payload.get("tool_input", {}).get("command", ""))
    if event == "PostToolUse":
        check_written(payload)
    # Loop guard, don't thrash on something the model can't fix.
    if payload.get("stop_hook_active"):
        sys.exit(0)
    check_diff()


if __name__ == "__main__":
    main()
