return {
	"tris203/precognition.nvim",
	event = "VeryLazy", -- Load the plugin lazily for better startup time
	config = {
		startVisible = true, -- Show hints immediately when moving cursor
		showBlankVirtLine = true, -- Show virtual lines for better visibility
		highlightColor = { link = "Comment" }, -- Make hints subtle but visible

		-- Motion hints configuration
		hints = {
			-- Basic character movements
			Caret = { text = "^", prio = 8 }, -- Beginning of line (non-blank)
			Dollar = { text = "$", prio = 8 }, -- End of line
			MatchingPair = { text = "%", prio = 9 }, -- Matching brackets
			Zero = { text = "0", prio = 7 }, -- Start of line

			-- Word movements (different priorities for better visual hierarchy)
			w = { text = "w", prio = 10 }, -- Next word start
			b = { text = "b", prio = 10 }, -- Previous word start
			e = { text = "e", prio = 9 }, -- Next word end

			-- WORD movements (slightly lower priority than word movements)
			W = { text = "W", prio = 7 }, -- Next WORD start
			B = { text = "B", prio = 7 }, -- Previous WORD start
			E = { text = "E", prio = 6 }, -- Next WORD end

			-- Additional useful movements
			f = { text = "f", prio = 5 }, -- Find character forward
			t = { text = "t", prio = 5 }, -- Till character forward
			F = { text = "F", prio = 5 }, -- Find character backward
			T = { text = "T", prio = 5 }, -- Till character backward
		},

		-- Gutter hints for larger movements
		gutterHints = {
			G = { text = "G", prio = 10 }, -- End of file
			gg = { text = "gg", prio = 10 }, -- Start of file
			PrevParagraph = { text = "{", prio = 8 }, -- Previous paragraph
			NextParagraph = { text = "}", prio = 8 }, -- Next paragraph

			-- Additional gutter hints for better navigation
			H = { text = "H", prio = 7 }, -- High screen position
			M = { text = "M", prio = 7 }, -- Middle screen position
			L = { text = "L", prio = 7 }, -- Low screen position

			-- Search result indicators
			n = { text = "n", prio = 6 }, -- Next search result
			N = { text = "N", prio = 6 }, -- Previous search result
		},

		-- Custom options for better integration
		updateTime = 100, -- Faster updates for smoother experience
		maxLines = 1000, -- Limit for better performance in large files
		minDistance = 3, -- Minimum distance between hints
	},
}
