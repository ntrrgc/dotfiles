#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

pushd "$DIR" >/dev/null
git submodule init
git submodule update
popd >/dev/null

ENTITIES=(.vim .vimrc .gitignore_global .gitconfig .bashrc .inputrc .ackrc)
for entity in ${ENTITIES[@]}; do
  if [ ! -L "$HOME/$entity" ]; then
    ln -s "$DIR/$entity" "$HOME/$entity"
  fi
done

mkdir -p "$HOME/.config/bspwm/"
ln -s "$DIR/bspwmrc" "$HOME/.config/bspwm/bspwmrc"
mkdir -p "$HOME/.config/sxhkd/"
ln -s "$DIR/sxhkdrc" "$HOME/.config/sxhkd/sxhkdrc"

mkdir -p "$HOME/.config/fish/"
ln -s "$DIR/fish/config.fish" "$HOME/.config/fish/config.fish"

if [ ! -L "$HOME/.vim/spell" ]; then
  ln -s "$HOME/Dropbox/vim-spell" "$HOME/.vim/spell"
fi
