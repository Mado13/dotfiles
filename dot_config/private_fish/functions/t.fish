function t --description "attach or create a tmux session for a project dir"
    set -l dir $argv[1]

    if test -z "$dir"
        # current sessions first, then zoxide's frecency list
        set dir (begin
                tmux list-sessions -F '#{session_path}' 2>/dev/null
                zoxide query -l
            end | awk '!seen[$0]++' | fzf --reverse --height 40% \
                --preview 'lsd -1 --color always {} 2>/dev/null; or ls -1 {}')
    end

    test -z "$dir"; and return

    # session names can't hold . or :
    set -l name (basename $dir | string replace -a -r '[.:]' _)

    tmux new-session -dA -s $name -c $dir
    if set -q TMUX
        tmux switch-client -t $name
    else
        tmux attach -t $name
    end
end
