function ll --description 'List contents of directory using long format'
    lsd --long --header --group-directories-first --blocks permission,user,group,size,date,name --date relative $argv
end

function lt --description 'List contents of directory in tree format'
    lsd --tree --depth 2 --group-directories-first $argv
end

function la --description 'List all contents of directory using long format'
    lsd --long --header --group-directories-first --blocks permission,user,group,size,date,name --date relative --all $argv
end

function lsize --description 'List contents sorted by size'
    lsd --long --header --group-directories-first --blocks permission,size,date,name --date relative --sort size --reverse $argv
end

function lmod --description 'List contents sorted by modification date'
    lsd --long --header --group-directories-first --blocks permission,size,date,name --date relative --sort date --reverse $argv
end

function lgit --description 'List contents with git status integration'
    lsd --long --header --group-directories-first --blocks git,permission,size,date,name --date relative $argv
end

function ldev --description 'List contents focused on development files'
    lsd --long --header --group-directories-first --blocks permission,size,date,git,name \
        --date relative \
        --ignore-glob .git,node_modules,target,build,dist \
        $argv
end

function ldocker --description 'List contents focused on Docker files'
    lsd --long --header --group-directories-first \
        --blocks permission,size,date,name \
        --date relative \
        --ignore-glob "!(Dockerfile|docker-compose.*|.dockerignore)" \
        $argv
end

function lcode --description 'List only code files'
    # Find files with specific extensions and pipe to lsd
    find . -type f \( \
        -name "*.py" -o \
        -name "*.js" -o \
        -name "*.ts" -o \
        -name "*.rb" -o \
        -name "*.go" -o \
        -name "*.rs" -o \
        -name "*.cpp" -o \
        -name "*.c" -o \
        -name "*.h" -o \
        -name "*.java" -o \
        -name "*.kt" -o \
        -name "*.cs" -o \
        -name "*.php" \
    \) -print0 | xargs -0 lsd --long --header \
        --blocks permission,size,date,name \
        --date relative
end

# Advanced git-aware listing
function lgitmod --description 'List only git modified files with clear status'
    if not test -d .git
        echo "Not a git repository"
        return 1
    end

    # Print status legend
    echo "Git Status Legend:"
    echo ".M = Modified in working directory"
    echo "M. = Modified and staged"
    echo ".A = Newly added file"
    echo ".? = Untracked file"
    echo ".D = Deleted in working directory"
    echo "D. = Deleted and staged"
    echo "R. = Renamed/moved file"
    echo
    echo "First column = Staged status"
    echo "Second column = Unstaged status"
    echo "----------------------------------------"
    echo

    # Get modified files and show them with lsd
    set -l modified_files (git status --porcelain | awk '{print $2}')
    if test -n "$modified_files"
        lsd --long --header \
            --blocks git,permission,size,date,name \
            --date relative \
            $modified_files
    else
        echo "No modified files in git"
    end
end

function lrails --description 'List recently modified Rails files by component'
    set -l component $argv[1]
    set -l days $argv[2]
    test -z "$days"; and set days 7

    switch $component
        case "models" "m"
            find app/models -type f -mtime -$days -name "*.rb" -print0 | \
            xargs -0 lsd --long --header --blocks permission,size,date,git,name
        case "controllers" "c"
            find app/controllers -type f -mtime -$days -name "*.rb" -print0 | \
            xargs -0 lsd --long --header --blocks permission,size,date,git,name
        case "views" "v"
            find app/views -type f -mtime -$days \( -name "*.erb" -o -name "*.haml" -o -name "*.slim" \) -print0 | \
            xargs -0 lsd --long --header --blocks permission,size,date,git,name
        case "all" "*"
            find app config lib test spec -type f -mtime -$days -print0 2>/dev/null | \
            xargs -0 lsd --long --header --blocks permission,size,date,git,name
    end
end

# Project-specific listing
function lproj --description 'Smart project file listing for Rails, JS/TS, and Elixir projects'
    # Project type detection (keeping existing detection logic)
    set -l project_type "unknown"
    
    if test -f mix.exs
        set project_type "elixir"
    else if test -f config/application.rb; or test -f Gemfile
        set project_type "rails"
    else if test -f package.json
        set -l package_content (cat package.json)
        if echo $package_content | grep -q '"svelte":'
            set project_type "svelte"
        else if echo $package_content | grep -q '"react":'
            set project_type "react"
        else
            set project_type "node"
        end
    end

    set -l component $argv[1]

    switch $project_type
        case "rails"
            echo "🛤️ Rails Project"
            switch $component
                case "models" "m"
                    echo "📦 Models:"
                    find app/models -type f -name "*.rb" -print0 | \
                    xargs -0 lsd --long --header \
                        --blocks permission,size,date,git,name \
                        --date relative

                case "controllers" "c"
                    echo "🎮 Controllers:"
                    find app/controllers -type f -name "*.rb" -print0 | \
                    xargs -0 lsd --long --header \
                        --blocks permission,size,date,git,name \
                        --date relative

                case "views" "v"
                    echo "👁️ Views:"
                    find app/views -type f \( -name "*.erb" -o -name "*.haml" -o -name "*.slim" \) -print0 | \
                    xargs -0 lsd --long --header \
                        --blocks permission,size,date,git,name \
                        --date relative

                case "helpers" "h"
                    echo "🤝 Helpers:"
                    find app/helpers -type f -name "*.rb" -print0 | \
                    xargs -0 lsd --long --header \
                        --blocks permission,size,date,git,name \
                        --date relative

                case "mailers" "mail"
                    echo "📧 Mailers:"
                    find app/mailers -type f -name "*.rb" -print0 | \
                    xargs -0 lsd --long --header \
                        --blocks permission,size,date,git,name \
                        --date relative

                case "jobs" "j"
                    echo "⚡ Jobs:"
                    find app/jobs -type f -name "*.rb" -print0 | \
                    xargs -0 lsd --long --header \
                        --blocks permission,size,date,git,name \
                        --date relative

                case "migrations" "db"
                    echo "🗄️ Migrations:"
                    find db/migrate -type f -name "*.rb" -print0 | \
                    xargs -0 lsd --long --header \
                        --blocks permission,size,date,git,name \
                        --date relative

                case "specs" "tests" "t"
                    echo "🧪 Tests:"
                    for dir in spec test
                        if test -d $dir
                            echo "Directory: $dir"
                            find $dir -type f \( -name "*_spec.rb" -o -name "*_test.rb" \) -print0 | \
                            xargs -0 lsd --long --header \
                                --blocks permission,size,date,git,name \
                                --date relative
                            echo
                        end
                    end

                case "config" "conf"
                    echo "⚙️ Configuration:"
                    find config -type f \( -name "*.rb" -o -name "*.yml" \) -print0 | \
                    xargs -0 lsd --long --header \
                        --blocks permission,size,date,git,name \
                        --date relative

                case "routes" "r"
                    echo "🛣️ Routes:"
                    lsd --long --header \
                        --blocks permission,size,date,git,name \
                        --date relative \
                        config/routes.rb

                case "gems" "g"
                    echo "💎 Gemfile:"
                    lsd --long --header \
                        --blocks permission,size,date,git,name \
                        --date relative \
                        Gemfile Gemfile.lock

                case "assets" "a"
                    echo "🎨 Assets:"
                    for dir in app/assets app/javascript
                        if test -d $dir
                            echo "Directory: $dir"
                            find $dir -type f -print0 | \
                            xargs -0 lsd --long --header \
                                --blocks permission,size,date,git,name \
                                --date relative
                            echo
                        end
                    end

                case "concerns" "con"
                    echo "🔄 Concerns:"
                    find app/controllers/concerns app/models/concerns -type f -name "*.rb" -print0 2>/dev/null | \
                    xargs -0 lsd --long --header \
                        --blocks permission,size,date,git,name \
                        --date relative

                case "services" "s"
                    echo "🔧 Services:"
                    find app/services -type f -name "*.rb" -print0 2>/dev/null | \
                    xargs -0 lsd --long --header \
                        --blocks permission,size,date,git,name \
                        --date relative

                case "api" "a"
                    echo "🔌 API Controllers:"
                    find app/controllers/api -type f -name "*.rb" -print0 2>/dev/null | \
                    xargs -0 lsd --long --header \
                        --blocks permission,size,date,git,name \
                        --date relative

                case '*'
                    echo "📂 Project Structure Overview:"
                    
                    # Core MVC components
                    echo "Models, Views, Controllers:"
                    for dir in app/models app/views app/controllers
                        if test -d $dir
                            echo "Directory: $dir"
                            lsd --long --header \
                                --blocks permission,size,date,git,name \
                                --date relative \
                                $dir
                            echo
                        end
                    end

                    # Additional components
                    echo "Additional Components:"
                    for dir in app/helpers app/mailers app/jobs app/services
                        if test -d $dir
                            echo "Directory: $dir"
                            lsd --long --header \
                                --blocks permission,size,date,git,name \
                                --date relative \
                                $dir
                            echo
                        end
                    end

                    # Config and DB
                    echo "Configuration and Database:"
                    for dir in config db
                        if test -d $dir
                            echo "Directory: $dir"
                            lsd --long --header \
                                --blocks permission,size,date,git,name \
                                --date relative \
                                $dir
                            echo
                        end
                    end

                    # Assets and Tests
                    echo "Assets and Tests:"
                    for dir in app/assets app/javascript spec test
                        if test -d $dir
                            echo "Directory: $dir"
                            lsd --long --header \
                                --blocks permission,size,date,git,name \
                                --date relative \
                                $dir
                            echo
                        end
                    end
            end

        # Keep other cases (elixir, svelte, react) as they were...
        case "elixir"
            # Previous Elixir implementation
        case "svelte"
            # Previous Svelte implementation
        case "react"
            # Previous React implementation
    end
end

# Recent files listing
function lrecent --description 'List recently modified files'
    # Using find to get recent files and pipe to lsd
    find . -type f -mtime -7 -print0 | xargs -0 lsd --long --header \
        --blocks permission,size,date,name \
        --date relative \
        --sort time \
        --reverse
end

# Size-focused listing with human-readable threshold
function lbig --description 'List files larger than specified size (default 100MB)'
    set -l size_threshold $argv[1]
    test -z "$size_threshold"; and set size_threshold "100M"
    
    find . -type f -size +$size_threshold -exec lsd --long --header \
        --blocks permission,size,date,name \
        --date relative \
        --sort size \
        --reverse {} +
end

# Quick directory size summary
function lsize-dirs --description 'List directories sorted by size'
    du -h --max-depth=1 | sort -hr | while read -l size dir
        lsd --long --header \
            --blocks size,name \
            --no-symlink \
            $dir
    end
end
