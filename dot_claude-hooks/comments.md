# Comments

IMPORTANT: default to zero comments. In a labelled study of 2,447 inline
comments, 30.8% were the "obvious" smell, restating the adjacent code. That is
the largest single category, bigger than every other smell combined. Assume the
comment you are about to write is that one until it passes both tests below.

Two tests. Both must pass, or delete the comment.

1. **Abstraction.** The comment must sit at a different level than the code
   under it. Either more precise than the code (units, bounds, what empty
   means, a side effect) or more general than it (the reason, the constraint).
   Same level as the code means you are restating it.
2. **Authorship.** Could someone who has never seen this codebase write your
   comment just by reading the line below it? If yes, it carries no
   information. Delete it.

A comment is allowed only in one of these shapes:

- An external constraint, named: upstream bug, spec quirk, ordering
  requirement, library behaviour. Give the issue or URL.
- A deliberate deviation a reviewer would otherwise "fix".
- Precision a signature cannot carry: units, bounds, what empty or null
  means, a side effect.

Use different words from the identifiers on the line below. Overlapping
vocabulary is the mechanical signature of a restated comment.

**Length:** one line. Two only when a URL needs its own. YOU MUST NOT write a
comment longer than the code it explains. That is a design note, and it belongs
in the commit body or the PR, not in the file.

**Density:** most functions get zero. Do not comment every method for
consistency, because that evenness is itself the tell. Cluster comments only
where something is genuinely non-obvious.

YOU MUST NOT write:

- History. What the code was, what it replaced, what it was migrated from,
  what library it used to use. That is `git log`.
- Narration of the next line ("parse the hours", "load the config").
- Justification of an obvious guard, early return, or type narrowing.
- An API's documented general behaviour. Link the docs instead of pasting them.
- Section banners, decorative rules, or your own attribution.
- Anything addressed to the person you are talking to. A comment is for the
  next reader of the file, not a reply in this conversation.
