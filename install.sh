#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

ENTITIES=(.vim .vimrc .gitignore_global .gitconfig .bashrc)
for entity in ${ENTITIES[@]}; do
  if [ ! -L "$HOME/$entity" ]; then
    ln -s "$DIR/$entity" "$HOME/$entity"
  fi
done

if [ ! -L "$HOME/.vim/spell" ]; then
  ln -s "$HOME/Dropbox/vim-spell" "$HOME/.vim/spell"
fi
