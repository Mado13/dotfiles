local f = require("util.functions")
local c = require("util.utils").create_cmd

c("BufOnlyWindowOnly", f.buf_only)
c("WinOnly", function()
	f.win_only()
end)
c("WinOnlyFocusLeft", function()
	f.win_only(function()
		vim.cmd("vsplit")
	end)
end)
c("WinOnlyFocusRight", function()
	f.win_only(function()
		vim.cmd("vsplit")
		vim.cmd.wincmd("h")
	end)
end)
c("WinOnlyFocusDown", function()
	f.win_only(function()
		vim.cmd("split")
		vim.cmd.wincmd("j")
	end)
end)
c("WinOnlyFocusUp", function()
	f.win_only(function()
		vim.cmd("split")
		vim.cmd.wincmd("k")
	end)
end)
c("CommentYankPaste", f.comment_yank_paste)
c("HelpWord", f.help_word)
c("LoadPreviousBuffer", f.load_previous_buffer)
c("ReloadLua", f.reload_lua)
c("SpectreOpen", f.spectre_open)
c("SpectreOpenWord", f.spectre_open_word)
c("SpectreOpenCwd", f.spectre_open_cwd)
c("SpotifyNext", function()
	f.run_system_command({
		cmd = [[spotify_player playback next && spotify_player get key playback | jq -r '.item | "\(.artists | map(.name) | join(", ")) - \(.name)"']],
		notify = true,
		notify_config = { title = "Spotify", render = "compact" },
	})
end)
c("SpotifyPrev", function()
	f.run_system_command({
		cmd = [[spotify_player playback previous && spotify_player get key playback | jq -r '.item | "\(.artists | map(.name) | join(", ")) - \(.name)"']],
		notify = true,
		notify_config = { title = "Spotify", render = "compact" },
	})
end)
c("TagStackDown", function()
	f.tagstack_navigate({ direction = "down" })
end)
c("TagStackUp", function()
	f.tagstack_navigate({ direction = "up" })
end)
c("ToggleCmdHeight", f.toggle_cmdheight)
c("ToggleTermFish", function()
	f.toggle_term_cmd({ count = 4, cmd = "fish" })
end)
c("ToggleTermLazyDocker", function()
	f.toggle_term_cmd({ count = 2, cmd = "lazydocker" })
end)
c("ToggleTermLazyGit", function()
	f.toggle_term_cmd({ count = 3, cmd = "lazygit" })
end)
c("ToggleTermWeeChat", function()
	f.toggle_term_cmd({ count = 5, cmd = "weechat" })
end)
c("ToggleTermPowershell", function()
	f.toggle_term_cmd({ count = 10, cmd = "pwsh" })
end)
c("ToggleTermRepl", function()
	f.toggle_term_cmd({ count = 8, cmd = { "node", "lua", "irb", "fish", "bash", "python" } })
end)
c("ToggleTermSpotify", function()
	f.toggle_term_cmd({ count = 1, cmd = "spotify_player" })
end)
c("WilderUpdateRemotePlugins", f.wilder_update_remote_plugins)
c("UpdateAndSyncAll", f.update_all)
c("UfoToggleFold", f.ufo_toggle_fold)
c("FoldParagraph", f.fold_paragraph)
c("HoverHandler", require("util.utils").hover_handler)
c("TerminalSendCmd", function()
	f.terminal_send_cmd("ls")
end)
c("TabNext", function()
	f.tabnavigate({ navto = "next" })
end)
c("TabPrevious", function()
	f.tabnavigate({ navto = "prev" })
end)
c("DisableLSPFormatting", function()
	f.lsp_formatting({ enable = false })
end)
c("EnableLSPFormatting", function()
	f.lsp_formatting({ enable = true })
end)
c("PersistenceLoad", function()
	require("persistence").load()
end)
c("DiffviewPrompt", require("util.diffview").open)
c("TF", f.testing_function)

vim.api.nvim_create_user_command("ToggleESLint", function()
	require("null-ls").toggle("eslint")
end, {})

vim.api.nvim_create_user_command("ToggleDiagnostics", function()
	if vim.g.diagnostics_enabled == nil then
		vim.g.diagnostics_enabled = false
		vim.diagnostic.disable()
	elseif vim.g.diagnostics_enabled then
		vim.g.diagnostics_enabled = false
		vim.diagnostic.disable()
	else
		vim.g.diagnostics_enabled = true
		vim.diagnostic.enable()
	end
end, {})

vim.api.nvim_create_user_command("CopyFilePathToClipboard", function()
	vim.fn.setreg("+", vim.fn.expand("%:p"))
end, {})

vim.api.nvim_create_user_command("RotateWindows", function()
	local ignored_filetypes = { "neo-tree", "fidget", "Outline", "toggleterm", "qf", "notify" }
	local window_numbers = vim.api.nvim_tabpage_list_wins(0)
	local windows_to_rotate = {}

	for _, window_number in ipairs(window_numbers) do
		local buffer_number = vim.api.nvim_win_get_buf(window_number)
		local filetype = vim.bo[buffer_number].filetype

		if not vim.tbl_contains(ignored_filetypes, filetype) then
			table.insert(windows_to_rotate, { window_number = window_number, buffer_number = buffer_number })
		end
	end

	local num_eligible_windows = vim.tbl_count(windows_to_rotate)

	if num_eligible_windows == 0 then
		return
	elseif num_eligible_windows == 1 then
		vim.api.nvim_err_writeln("There is no other window to rotate with.")
		return
	elseif num_eligible_windows == 2 then
		local firstWindow = windows_to_rotate[1]
		local secondWindow = windows_to_rotate[2]

		vim.api.nvim_win_set_buf(firstWindow.window_number, secondWindow.buffer_number)
		vim.api.nvim_win_set_buf(secondWindow.window_number, firstWindow.buffer_number)
	else
		vim.api.nvim_err_writeln("You can only swap 2 open windows. Found " .. num_eligible_windows .. ".")
	end
end, {})
