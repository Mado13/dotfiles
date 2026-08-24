function cc-switch
    claude logout 2>/dev/null
    python3 -c "
import json
p = '$HOME/.claude.json'
d = json.load(open(p))
d.pop('oauthAccount', None)
json.dump(d, open(p, 'w'), indent=2)
"
    claude
end
