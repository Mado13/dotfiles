function __cc_subcommands --description 'claude subcommands, which must come before any flag'
    echo agents attach auth auto-mode doctor gateway import install logs mcp \
        plugin plugins project respawn rm setup-token stop kill ultrareview \
        update upgrade | string split ' '
end
