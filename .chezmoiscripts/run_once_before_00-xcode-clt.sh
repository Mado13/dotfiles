#!/bin/bash
set -eu

if xcode-select -p >/dev/null 2>&1; then
    echo "xcode command line tools: already there"
    exit 0
fi

echo "installing xcode command line tools, accept the GUI prompt"
xcode-select --install || true

# The installer is a separate GUI process, so this loop is the only way to
# wait for it. Nothing after this point works without the tools.
until xcode-select -p >/dev/null 2>&1; do
    sleep 15
    echo "  still waiting..."
done
echo "xcode command line tools: done"
