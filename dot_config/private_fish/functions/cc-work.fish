function cc-work
    # comments.md goes in the real system prompt, not CLAUDE.md. CLAUDE.md is
    # injected wrapped in "this context may or may not be relevant", which is
    # why a comment rule there holds for about one turn and then regresses.
    # `string collect` keeps the file as one argument, fish splits on newlines.
    CLAUDE_CONFIG_DIR=$HOME/.claude-work \
        claude --append-system-prompt (cat $HOME/.claude-hooks/comments.md | string collect) $argv
end
