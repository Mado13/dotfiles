function flog --description "readable live tail of fly logs"
    argparse a/app= e/errors A/all n/no-tail -- $argv
    or return

    set -l app tempi-api
    set -q _flag_app; and set app $_flag_app

    set -l tail
    set -q _flag_no_tail; and set tail --no-tail

    # fly -j wraps the real line as a json string in .message, so parse twice
    set -l unwrap '.message | fromjson? // empty'

    if set -q _flag_all
        # thruster logs every request as well, in its own shape. raw, since the
        # two shapes share no fields worth mapping
        fly logs -a $app -j $tail | jq -C --unbuffered $unwrap
        return
    end

    # thruster's lines carry `msg` where semantic_logger carries `message`.
    # this also drops every /up health check, which only thruster logs
    set -l filter ' | select(.msg == null)'
    set -q _flag_errors; and set filter $filter ' | select(.level == "error")'

    set -l shape ' | {time: .timestamp[11:19], level, req: .named_tags.request_id[0:8]}
        + (.payload // {})
        + (if .exception then {error: "\(.exception.name): \(.exception.message)", at: .exception.stack_trace[0]} else {} end)'

    # string collect, or the newlines in $shape split the substitution into three args
    set -l prog (string join '' $unwrap $filter $shape | string collect)

    fly logs -a $app -j $tail | jq -C --unbuffered $prog
end
