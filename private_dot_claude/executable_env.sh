#!/usr/bin/env bash

# ~/.claude/env.sh
# Sourced by Claude Code before every bash command via CLAUDE_ENV_FILE.
# Mirrors the Fish shell environment so Claude Code sees the same tools.

# ── Homebrew ──────────────────────────────────────────────────────────
eval "$(/opt/homebrew/bin/brew shellenv)"

# ── Cargo / Rust tools (rv binary lives here, plus other Rust CLIs) ──
export PATH="$HOME/.cargo/bin:$PATH"

# ── Bun ───────────────────────────────────────────────────────────────
export PATH="$HOME/.bun/bin:$PATH"

# ── Personal bins ─────────────────────────────────────────────────────
export PATH="$HOME/.bin:$HOME/.local/bin:$PATH"

# ── Postgres (Postgres.app) ──────────────────────────────────────────
export PATH="/Applications/Postgres.app/Contents/Versions/17/bin:$PATH"

# ── Java ──────────────────────────────────────────────────────────────
export JAVA_HOME="/Library/Java/JavaVirtualMachines/temurin-21.jdk/Contents/Home"

# ── Locale ────────────────────────────────────────────────────────────
export LANG="en_US.UTF-8"

# ── Build flags (needed for native gem extensions) ────────────────────
export LDFLAGS="-L/opt/homebrew/opt/readline/lib"
export CPPFLAGS="-I/opt/homebrew/opt/readline/include"

# ── Claude Code performance tuning ────────────────────────────────────

# Use your system ripgrep instead of the bundled Node.js wrapper.
# Claude Code's Grep tool is actually powered by ripgrep under the hood.
# The bundled version goes through a Node.js wrapper adding 5-10x overhead.
# This tells it to use /opt/homebrew/bin/rg directly.
export USE_BUILTIN_RIPGREP=0

# ── rv (Ruby version manager), last so nothing reorders ruby after it ─
# Sets RUBY_ROOT, GEM_HOME, GEM_PATH, PATH per .ruby-version.
# Absolute path so PATH order never picks the rv. Brew keeps this one current.
# zsh init when we can get it: its chpwd hook re-activates on cd, while the bash
# init hangs the hook on PROMPT_COMMAND, which never fires non-interactively.
if [ -n "$ZSH_VERSION" ]; then
    eval "$(/opt/homebrew/bin/rv shell init zsh)"
else
    eval "$(/opt/homebrew/bin/rv shell init bash)"
fi

# Binstubs: puts each project's bin/ on PATH so rake gets the locked version.
if [ -n "$ZSH_VERSION" ]; then
    eval "$(/opt/homebrew/bin/direnv hook zsh)"
else
    eval "$(/opt/homebrew/bin/direnv hook bash)"
fi
