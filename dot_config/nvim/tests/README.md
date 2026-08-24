# circleci tests

Offline tests for `lua/circleci.lua`. Fixtures are real payloads captured from
the work projects, so the parsers are checked against what CircleCI and
jj actually emit rather than what the docs imply.

    for t in parsing push_detection outcomes; do nvim --clean --headless -l tests/$t.lua; done

- `parsing.lua` - test-result and job payloads, backtrace frames, re-run dedup
- `push_detection.lua` - jj op log parsing, against a real 300-op log
- `outcomes.lua` - every outcome and phase value, plus degenerate payloads

The push watch, statusline and trouble integration were verified against the
live API instead; those need network and a real project so they are not here.
