#!/bin/bash
set -eu

echo "==> macOS defaults"

# Values read off the old machine, not guesses. Edit here, not in System
# Settings, so the next restore keeps them.

# Keyboard: fastest repeat the sliders allow, and hold-a-key repeats
# instead of opening the accent picker.
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 10
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Trackpad: tap-to-click off, physical click only.
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool false

defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.finder _FXSortFoldersFirst -bool true

defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -int 38
defaults write com.apple.dock show-recents -bool false

# AeroSpace does the tiling, so macOS must stop reshuffling spaces underneath it.
defaults write com.apple.dock mru-spaces -bool false
defaults write com.apple.spaces spans-displays -bool true

defaults write com.apple.screencapture disable-shadow -bool true
defaults write com.apple.screencapture type -string "png"

defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write com.apple.LaunchServices LSQuarantine -bool false

killall Dock Finder SystemUIServer 2>/dev/null || true

cat <<'EOF'

Not scriptable, do these by hand in System Settings:
  - Accessibility > Zoom (scroll gesture with modifier)
  - Keyboard > Shortcuts, whatever AeroSpace needs granted
  - Privacy & Security > Accessibility, add AeroSpace, Maccy, Sol, rcmd
  - Touch ID, FileVault, Apple ID / iCloud

An MDM profile wins over every `defaults write` above. If a setting snaps
back after a while, that is Intune, not this script.
EOF
