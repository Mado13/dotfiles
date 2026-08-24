#!/bin/bash
set -eu

if command -v brew >/dev/null 2>&1; then
    echo "homebrew: already on PATH"
    exit 0
fi

if [ -x /opt/homebrew/bin/brew ]; then
    echo "homebrew: installed but not on PATH yet, fine, 00-env.fish adds it"
    exit 0
fi

# An MDM policy can chown /opt/homebrew to root to lock brew out. Detect that
# instead of failing halfway through the installer.
if [ -d /opt/homebrew ] && [ ! -w /opt/homebrew ]; then
    cat >&2 <<'EOF'
/opt/homebrew exists and is not writable by you.

That is what an Intune "block Homebrew" policy looks like. Nothing here can
work around it, and it should not try. Ask IT whether brew is allowed on this
machine. Meanwhile the shell and editor configs are all applied already, and
the fallback is a userland prefix:

  git clone https://github.com/Homebrew/brew ~/.homebrew
  eval "$(~/.homebrew/bin/brew shellenv)"

Bottles do not work from a non-standard prefix, so everything builds from
source and it is slow. Treat it as a stopgap.
EOF
    exit 1
fi

echo "installing homebrew"
NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
