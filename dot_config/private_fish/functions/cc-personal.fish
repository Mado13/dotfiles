function cc-personal
    # see cc-work for why this is a system prompt append and not CLAUDE.md
    if contains -- "$argv[1]" (__cc_subcommands)
        CLAUDE_CONFIG_DIR=$HOME/.claude-personal claude $argv
        return
    end
    CLAUDE_CONFIG_DIR=$HOME/.claude-personal \
        claude --append-system-prompt (cat $HOME/.claude-shared/{voice,comments,writing-for-models}.md | string collect) $argv
end
