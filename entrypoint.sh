#!/bin/sh
CODEDIR=/code

# symlink project configuration directories into user's home
for link in $POPULATE; do
  [ ! -e ~/$link -a -e $CODEDIR/$link ] && ln -s $CODEDIR/$link ~
done

[ -n "$*" ] && exec $@ || exec /bin/zsh
