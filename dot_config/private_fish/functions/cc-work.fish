function cc-work
    # the voice and comment rules go in the real system prompt, not CLAUDE.md.
    # CLAUDE.md is injected wrapped in "this context may or may not be relevant",
    # which is why a rule there holds for about one turn and then regresses.
    # `string collect` keeps the text as one argument, fish splits on newlines.
    if contains -- "$argv[1]" (__cc_subcommands)
        # a subcommand has to be the first arg. put --append-system-prompt in
        # front of it and claude eats the subcommand as a prompt instead
        CLAUDE_CONFIG_DIR=$HOME/.claude-work claude $argv
        return
    end
    CLAUDE_CONFIG_DIR=$HOME/.claude-work \
        claude --append-system-prompt (cat $HOME/.claude-shared/{voice,comments,writing-for-models}.md | string collect) $argv
end
