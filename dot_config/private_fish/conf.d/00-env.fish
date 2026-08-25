# runs in every fish shell, interactive or not. non-interactive fish matters:
# hooks and scripts get their env from here, and so does anything claude code
# inherits from the shell it was launched in. the bash tool itself is zsh, it
# reads ~/.claude/env.sh instead. keep the rv line below in sync with that file.
# anything inside `status is-interactive` in config.fish is invisible to them.

# homebrew first, then the user bins
fish_add_path --global --path --prepend /opt/homebrew/bin /opt/homebrew/sbin
fish_add_path --global --path --prepend /opt/homebrew/opt/postgresql@17/bin
fish_add_path --global --path --prepend /opt/homebrew/opt/libxml2/bin
fish_add_path --global --path --prepend ~/.bun/bin ~/.local/bin ~/.cargo/bin

# rv owns ruby, and it has to be out here. inside the interactive guard a
# non-interactive shell keeps the parent's ruby, so a repo ran the wrong one
# absolute path so PATH order never picks the rv. brew keeps this one current
/opt/homebrew/bin/rv shell init fish | source

# puts each project's bin/ on PATH, so rake resolves the Gemfile.lock version
direnv hook fish | source
