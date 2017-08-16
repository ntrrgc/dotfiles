#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

pushd "$DIR" >/dev/null
git submodule init
git submodule update
popd >/dev/null

gcc "$DIR/bin/find-holes-in-file.c" -o "$DIR/bin/find-holes-in-file" -Wall -pedantic -O2 -g

# Get the path to dotfiles from $HOME
RELADIR="$( realpath --relative-to "$HOME" "$DIR" )"
cd "$HOME"

ENTITIES=(.vim .vimrc .gitignore_global .gitconfig .bashrc .inputrc .ackrc .gdbinit)
for entity in ${ENTITIES[@]}; do
  if [ ! -L "$HOME/$entity" ]; then # If file in ~/ is not a symlink...
    if [ -f "$HOME/$entity" ]; then
      # Backup existing file first
      mv "$HOME/$entity" "$HOME/$entity.bak"
    fi
    ln -r -s "$RELADIR/$entity" "$HOME/$entity"
  fi
done

mkdir -p "$HOME/.config/bspwm/"
ln -r -s "$RELADIR/bspwmrc" "$HOME/.config/bspwm/bspwmrc"
mkdir -p "$HOME/.config/sxhkd/"
ln -r -s "$RELADIR/sxhkdrc" "$HOME/.config/sxhkd/sxhkdrc"

mkdir -p "$HOME/.config/fish/"
ln -r -s "$RELADIR/fish/config.fish" "$HOME/.config/fish/config.fish"

if [ ! -L "$HOME/.vim/spell" ]; then
  ln -s "$HOME/Dropbox/vim-spell" "$HOME/.vim/spell"
fi

vim +PluginInstall +qall
