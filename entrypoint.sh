#!/bin/sh

## copy skeleton into actual $HOME (one time operation)
cwd=$(pwd) && cd /home/_home-skeleton_
ls -a1 | sed '/^\(\.\|\.\.\)$/d' | xargs -I{} sh -c "test -e $HOME/{} || cp -ar {} ${HOME}"
cd "${cwd}"

## set up zsh
awk '/^plugins=\(/,/\)/ { if ( $0 ~ /^plugins=\(/ ) print "plugins=('"${ZSH_PLUGINS}"')"; next } 1' $HOME/.zshrc > /tmp/.zshrc
mv /tmp/.zshrc $HOME/.zshrc
sed -i 's/\(ZSH_THEME\)=".*"/\1="'${ZSH_THEME}'"/' $HOME/.zshrc
sed -i 's/#\'sed 's/^# *\(DISABLE_AUTO_UPDATE=\).*/\1true/'

# execute command or fallback into shell
[ -n "$*" ] && exec $@ || exec /bin/zsh
