function cc-personal
    # see cc-work for why this is a system prompt append and not CLAUDE.md
    CLAUDE_CONFIG_DIR=$HOME/.claude-personal \
        claude --append-system-prompt (cat $HOME/.claude-hooks/comments.md | string collect) $argv
end
