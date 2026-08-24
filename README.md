# dotfiles

macOS setup, managed with [chezmoi](https://chezmoi.io). Public on purpose: no
secrets and no employer identifiers live here, so restoring needs no
credentials.

## Restore on a fresh Mac

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply Mado13
```

That is the whole thing. It downloads chezmoi to `~/.local/bin`, clones this
repo to `~/.local/share/chezmoi`, asks the six questions below, writes every
config into place, then runs the scripts in `.chezmoiscripts/` in order:

| Script | What it does |
| --- | --- |
| `00-xcode-clt` | Installs the Xcode command line tools, waits for the GUI installer |
| `01-homebrew` | Installs Homebrew, or stops with a clear message if MDM has locked it |
| `10-brew-bundle` | `brew bundle` over the `Brewfile`, re-runs whenever it changes |
| `20-macos-defaults` | `defaults write` for keyboard, trackpad, Finder, Dock, spaces |
| `30-toolchains` | rustup, cargo tools, bun, npm globals, pipx, ruby, fisher, nvim plugins |

Then the two manual steps in [After the restore](#after-the-restore).

Day to day after that:

```sh
chezmoi edit ~/.config/fish/config.fish   # edit the source, not the target
chezmoi diff                              # what would change
chezmoi apply                             # write it
chezmoi cd && jj st                       # the repo itself
chezmoi add <path>                         # start tracking something new
```

## What is here

125-odd files. Fish (the real shell config, zsh stays thin and is the login
shell), git, ssh config, nvim, aerospace, ghostty and its Everforest theme,
wezterm, tmux, zellij, jj plus its four helper scripts, starship, zed, the
Claude Code voice hook, the SmartSet keyboard mapping, and the smaller TUI
configs. `Brewfile` covers 77 top-level formulae, 24 casks, and the 22 GUI apps
that used to be installed by hand.

Hardcoded `/Users/matan` paths became `{{ .chezmoi.homeDir }}` templates, so a
different username works.

## Before you wipe

Nothing below is in this repo, and a factory reset takes all of it.

- [ ] Push every repo under `~/code`. `~/code/credentials` in particular.
- [ ] `~/.ssh/id_ed25519` and `~/.ssh/proton_key` into 1Password or Bitwarden.
      Better: switch to the vault's SSH agent so there is no key file next time.
- [ ] `~/.ssh/config.work` (work hosts) as a secure note.
- [ ] All of `~/.config/chezmoi/chezmoi.toml`. It is the only place the work
      identifiers live, and restoring it skips the six prompts.
- [ ] The Obsidian vault in `~/Documents`.
- [ ] `~/.claude*` and `~/.config/zed/conversations` if the history matters.
- [ ] `mas list` after signing in to the App Store, the `Brewfile` section is
      incomplete because it came back empty here.

Re-auth after, no config to restore: `gh`, `gcloud`, `op`, 1Password, Bitwarden,
Docker, fly, render, heroku, circleci, neonctl, Copilot, CodeRabbit, Aikido.

## Local config, not in this repo

`chezmoi init` asks six questions and writes the answers to
`~/.config/chezmoi/chezmoi.toml`, which is never committed. That file is the
only place employer identifiers live:

```toml
[data]
    name      = "Your Name"
    email     = "primary@git.email"
    emails    = "one@x two@y three@z"   # space separated, every address you commit under
    workdir   = "<dir under ~/code>"    # blank for none
    workrepo  = "<repo name>"           # blank for none
    workemail = "work@git.email"        # blank for none

    gitEmails = ["one@x", "two@y", "three@z"]

[data.work]
    dir   = "<dir under ~/code>"
    name  = "<repo name>"
    email = "work@git.email"
```

The flat keys are the raw prompt answers, and `promptStringOnce` reads them back
so a re-init asks nothing. `gitEmails` and `[data.work]` are derived from them
and are what the target templates read. Never hand-edit only one half.

`gitEmails` feeds the jj `me()` revset. `[data.work]` feeds the jj
per-directory email scope, nvim's lint-as-format tree and Obsidian vault, the
zellij dev layout, and `rails.fish`. Leave the work answers blank and all four
fall back to something harmless.

Keep a copy of this file in Bitwarden. Restoring it before the first
`chezmoi apply` saves answering the prompts.

Two things the templates could not cover:

- **`~/.config/gh-dash/config.yml`.** gh-dash uses `{{.RepoPath}}` in its own
  keybindings, which collides with Go templates. Not worth escaping ten of
  them, so the file is a plain copy and these two rows are missing:

  ```yaml
  # under issuesSections:
    - title: " <NAME> - Current Sprint"
      filters: is:open project:<org>/<n> repo:"<org>/<repo>"
  # under repoPaths:
    <org>/<repo>: ~/code/<dir>/<repo>
  ```

- **`~/.config/fish/functions/<work>.fish`.** One function, untracked because
  its filename is the repo name:

  ```fish
  function <work>
      zellij --layout ~/.config/zellij/layouts/dev_environment.kdl
  end
  ```

## What is deliberately not here

Every line is a choice, not an oversight. `.chezmoiignore` names them so they
do not silently come back.

- **SSH private keys.** `~/.ssh/config` is tracked, the keys are not.
- **`~/.ssh/config.work`**, pulled in by an `Include` at the top of the tracked
  config.
- **`~/.config/fish/secrets.fish`.** `config.fish` sources it if present. API
  keys go there, `chmod 600`.
- **Credential and auth directories.** `~/.config/{gcloud,op,gh,1Password,
  circleci,neonctl,github-copilot}`, `~/.docker`, `~/.fly`, `~/.render`,
  `~/.aikido`, `~/.coderabbit`. Log in again instead.
- **`~/Library`.** VS Code's `settings.json` lives there, and chezmoi wanted to
  chmod the whole tree to 0700 to reach it. Two lines are not worth that:
  `{"svelte.enable-ts-plugin": true, "explorer.confirmDelete": false}`.
- **App plists** (`~/Library/Preferences/*.plist` for Sol, Marta, Obsidian,
  Hovrly). Mostly window state, and they go stale.
- **`~/.claude*`.** Next section.
- Shell history, caches, `fish_variables`, `.DS_Store`, `nvim.bak`.

### Secrets, when you want them in here

age with a passphrase is configured, so there is no key file to lose:

```sh
chezmoi add --encrypt ~/.config/fish/secrets.fish
```

It prompts on add and on every `apply`. Keep that passphrase in Bitwarden. With
no encrypted files present, nothing prompts.

## After the restore

### Claude Code config, still to add

`~/.claude`, `~/.claude-work`, and `~/.claude-personal` are not tracked. Only
the hand-written files are worth keeping, the rest of those directories is
session state and caches:

```sh
chezmoi add ~/.claude/CLAUDE.md ~/.claude/settings.json ~/.claude/env.sh
chezmoi add ~/.claude/themes/everforest.json
chezmoi add ~/.claude/skills/match-repo-voice/SKILL.md
chezmoi add ~/.claude-work/CLAUDE.md ~/.claude-work/settings.json
chezmoi add ~/.claude-personal/CLAUDE.md ~/.claude-personal/settings.json
```

`settings.json` sets `"theme": "custom:everforest"`, so it needs that theme
file or Claude falls back to the default. Check both `settings.json` files for
anything account-specific before committing.

`~/.claude-hooks/` (`comments.md`, `voice-check.py`) and the `cc-work` /
`cc-personal` launchers are already tracked, and `settings.json` points its
hooks at `$HOME/.claude-hooks/`, so that half works already.

### Not installable from a script

`30-toolchains.sh` prints these too:

- **`~/.safe-chain`** (Aikido). `.zshrc`, `.bashrc` and `config.fish` all end
  in a line that sources it. Until it exists those shells print one
  "no such file" per launch.
- **`~/google-cloud-sdk`.** `config.fish` sources its fish inc files.
- **Postgres.app.** `~/.claude/env.sh` puts its `17/bin` on PATH.

## Managed machine notes

This Mac gets Intune and SentinelOne. Both can break parts of the restore, and
none of it is worth fighting.

- **Homebrew can be blocked outright.** The usual Intune recipe chowns
  `/opt/homebrew` to root and shims `brew` so it looks present but never runs.
  `01-homebrew.sh` detects that and stops with an explanation instead of
  failing halfway. The fallback is a userland prefix in `~/.homebrew`, which
  means no bottles and everything builds from source. Ask IT first.
- **Losing local admin** breaks the one-time Homebrew install even when nothing
  is explicitly blocked.
- **Casks needing a system extension** (orbstack, malwarebytes,
  background-music) need admin approval or an MDM profile. Expect some of the
  24 to fail. `10-brew-bundle.sh` says so rather than pretending it passed.
- **An MDM configuration profile beats every `defaults write`.** If a setting
  snaps back, that is Intune.
- **SentinelOne taxes file I/O.** `bundle install`, `node_modules`, webpack
  watches, big `brew install` runs all get slower. Worth asking for path
  exclusions on the dev directories up front.

## Known wrinkles

`00-env.fish` and `~/.claude/env.sh` both call `$HOME/.cargo/bin/rv` by
absolute path, because the Homebrew `rv` activates `~/.rubies/ruby-3.3.2`
instead of honouring `.ruby-version`. The old binary was `cargo install`ed from
a checkout at `~/code/rv` that no longer exists, so `30-toolchains.sh` builds
it from `github.com/spinel-coop/rv` instead.

`chezmoi verify` exits 1 on a machine where the `run_once_` scripts have not
run. That is chezmoi counting a pending script as a difference, not a problem.
