#!/bin/bash
set -u

ok() { "$@" || echo "  ! failed, moving on: $*" >&2; }

[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

step() { echo; echo "==> $1"; }

step "rust toolchain"
if ! command -v rustup >/dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
fi
. "$HOME/.cargo/env"

step "cargo tools"
# 00-env.fish calls $HOME/.cargo/bin/rv by absolute path on purpose: the brew
# rv picks ~/.rubies/ruby-3.3.2 over the .ruby-version pin. So rv has to be
# here even though the Brewfile also installs it.
cargo install --locked --git https://github.com/spinel-coop/rv rv || \
    echo "  rv from git failed. 'brew install rv' is the fallback, but read the note in 00-env.fish first." >&2
ok cargo install --locked jj-starship
ok cargo install --locked spotify_player
ok cargo install --locked octorus
ok cargo install --locked --git https://gitlab.com/lanastara_foss/starship-jj starship-jj
ok cargo install --locked --git https://github.com/Cretezy/lazyjj.git lazyjj

step "bun"
command -v bun >/dev/null 2>&1 || curl -fsSL https://bun.sh/install | bash
ok "$HOME/.bun/bin/bun" add -g @fsouza/prettierd vercel

step "npm globals"
ok npm install -g \
    @agentclientprotocol/claude-agent-acp \
    @anthropic-ai/claude-agent-sdk \
    @vtsls/language-server \
    localtunnel \
    mcp-hub \
    neovim \
    quicktype \
    stimulus-language-server \
    svelte-language-server \
    typescript-svelte-plugin

step "pipx"
ok pipx install calcure
ok pipx install neovim-remote

step "ruby"
# ruby-install and rv both come from the Brewfile. 3.3.2 is what the old
# machine had in ~/.rubies; project .ruby-version files pin the rest.
"$HOME/.cargo/bin/rv" ruby install 3.3.2 || ruby-install ruby 3.3.2

step "fisher"
if command -v fish >/dev/null 2>&1; then
    fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher' || true
fi

step "neovim plugins"
# init.lua uses vim.pack, so a headless run resolves nvim-pack-lock.json.
command -v nvim >/dev/null 2>&1 && nvim --headless '+qa' || true

cat <<'EOF'

Left out on purpose, install by hand:
  - safe-chain (~/.safe-chain), sourced by every shell rc. Get it from
    Aikido, it is the reason .zshrc/.bashrc/config.fish end in a source line.
    Until it is there those shells print one "no such file" per launch.
  - Postgres.app, ~/.claude/env.sh puts its 17/bin on PATH.
  - google-cloud-sdk in ~/google-cloud-sdk, config.fish sources its fish inc.
EOF
