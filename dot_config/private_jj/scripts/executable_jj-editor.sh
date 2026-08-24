#!/usr/bin/env sh
# Always nvim, including inside nvim's own :terminal. The old nvr branch opened
# the message as a split, which moved focus off the jjui buffer, and jjui.nvim
# closes its float on BufLeave. So the float tore itself down mid-squash.
#
# The env var is read by ~/.config/nvim/ftplugin/jjdescription.lua. jj blocks on
# this nvim until it exits, so <leader>wd has to quit it rather than close a
# window, and that must not happen in a real session.
JJ_DESCRIPTION_EDITOR=1 exec nvim "$@"
