[[ -s "$HOME/.bashrc" ]] && source "$HOME/.bashrc"
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
[[ -s "$HOME/.travis/travis.sh" ]] && source "$HOME/.travis/travis.sh"

if [ -f ~/Workspace/bash-git-prompt/gitprompt.sh ]; then
  GIT_PROMPT_THEME=TruncatedPwd_WindowTitle_NoExitState_Ubuntu
  source ~/Workspace/bash-git-prompt/gitprompt.sh
fi

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export PATH="/usr/local/sbin:$PATH"
export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting
export PATH="$PATH:$GOPATH/bin"
export PATH="$PATH:$GOROOT/bin"

export NODE1=139.59.202.70
export NODE2=178.62.83.103
export NODE3=178.62.84.224
export NODE4=178.62.85.200
export GOPATH=$HOME/golang
export GOROOT=/usr/local/opt/go/libexec
