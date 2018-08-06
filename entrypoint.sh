#!/bin/sh
CODEDIR=/code

# symlink project configuration directories into user's home
for link in $POPULATE; do
  [ ! -e ~/$link -a -d $CODEDIR/$link ] && ln -s $CODEDIR/$link ~
done

[ -n "$*" ] && exec $@ || exec /bin/zsh
