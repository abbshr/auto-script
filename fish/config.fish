set EDITOR /usr/bin/subl
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias clang='clang-3.5'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# greetings help
cat $HOME/.config/fish/greet

function hp
  cat $HOME/.config/fish/greet
end
