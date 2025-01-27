if status is-interactive
  # Aliases
  alias code="nvim"
  alias restore_taxology='vmt restore --port 5432 --b2bucket "taxology-eu-db-backups" --b2encrypt "qG^w@~wST=sM2AI6Z.5VXz[9R5jQq:b9" --b2id "00349e35f357f0c000000000c" --b2key "K003BGiLNvSe9zYfScgQedNboZW3jBA"'
  alias set_gcloud_taxology='gcloud config set project taxology-381314;
    gcloud config set compute/zone europe-west1-b;
    gcloud container clusters get-credentials taxology
    gcloud components install kubectl'

  alias set_gcloud_voormedia='gcloud config set project voormedia-187708;
    gcloud config set compute/zone europe-west1-b;
    gcloud container clusters get-credentials voormedia-2;
    gcloud components install kubectl'

  alias set_gcloud_tinify='gcloud config set project tinify-160715;
    gcloud config set compute/zone europe-west1-b;
    gcloud container clusters get-credentials tinify-2;
    gcloud components install kubectl'

  # Google Cloud SDK path update
  if test -f /Users/Matan/google-cloud-sdk/path.fish.inc
      source /Users/Matan/google-cloud-sdk/path.fish.inc
  end

# Google Cloud SDK shell command completion
  if test -f /Users/Matan/google-cloud-sdk/completion.fish.inc
      source /Users/Matan/google-cloud-sdk/completion.fish.inc
  end


  # Environment variables
  set -gx PATH /opt/homebrew/bin /Users/Matan/.bin /opt/homebrew/opt/mysql@5.7/bin /opt/homebrew/opt/tomcat@9/bin /opt/homebrew/opt/libxml2/bin /opt/homebrew/opt/libxslt/bin /opt/homebrew/opt/php@7.0/bin /opt/homebrew/opt/php@7.0/sbin  $PATH
  set -gx CLOUDSDK_PYTHON /opt/homebrew/bin/python3
  set -gx PATH /usr/local/opt/ruby/bin $PATH
  set -gx CPPFLAGS "-I"(brew --prefix readline)"/include" $CPPFLAGS
  set -gx LDFLAGS "-L"(brew --prefix readline)"/lib" $LDFLAGS
  set -gx HF_TOKEN "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"
  set -x B2_TAXOLOGY_ACCOUNT_ID "00349e35f357f0c000000000c"
  set -x B2_TAXOLOGY_ACCOUNT_KEY "K003BGiLNvSe9zYfScgQedNboZW3jBA"
  set -x B2_TAXOLOGY_ENCRYPTION_KEY "qG^w@~wST=sM2AI6Z.5VXz[9R5jQq:b9"
  set -x B2_ACCOUNT_ID "0032a268ca5531e0000000028"
  set -x B2_ACCOUNT_KEY "K003OcowLmlKFvnhNH07i/2zQ9M9yxo"
  set -x B2_ENCRYPTION_KEY "fta%XXpfq._#}iEu5i_ZX%Jn5gIzs^WI"
  set -x PKG_CONFIG_PATH /opt/homebrew/opt/libffi/lib/pkgconfig:$PKG_CONFIG_PATH
  set -x RUBY_CONFIGURE_OPTS "--with-openssl-dir=$(brew --prefix openssl@1.1)"
  set -gx PATH ~/.asdf/shims ~/.asdf/bin $PATH
  set -x BUNDLER_EDITOR "nvim"
  set -Ux PATH /opt/homebrew/bin /opt/homebrew/sbin $PATH
  set -x PATH ~/.local/share/nvim/lsp_servers/elixir-ls/release/ $PATH
  set -gx PATH $HOME/development/flutter/bin $PATH
  set -gx PATH $HOME/.gem/bin $PATH
  set -x PATH $PATH ~/.bun/bin $PATH
  set -Ux ELECTRIC_CLIENT_VERSION 0.2.3

  source "/opt/homebrew/share/google-cloud-sdk/path.fish.inc"
  source /opt/homebrew/opt/asdf/libexec/asdf.fish

  function ya
    set tmp (mktemp -t "yazi-cwd.XXXXX")
    yazi $argv --cwd-file="$tmp"
    set cwd (cat -- "$tmp")
    if test -n "$cwd" -a "$cwd" != "$PWD"
        cd -- "$cwd"
    end
    rm -f -- "$tmp"
  end

  function mkcd
    mkdir -p $argv[1] && cd $argv[1]
  end

  function gs
    git status
  end

  function gp
    git pull --rebase
    and git push
  end

  function ff
    find . -type f | fzf --preview 'bat --style=numbers --color=always {}'
  end

  complete -c aws -f -a '(begin; set -lx COMP_SHELL fish; set -lx COMP_LINE (commandline); aws_completer; end)'

  set -Ux LSCOLORS gxfxcxdxbxegedabagacad

  bind \cr 'history-search-backward'
  bind \cf 'ff'

  zoxide init fish | source
  starship init fish | source
end
