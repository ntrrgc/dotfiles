#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

ENTITIES=(.vim .vimrc .gitignore_global .gitconfig)
for entity in ${ENTITIES[@]}; do
  ln -s "$DIR/$entity" "$HOME/$entity"
done
