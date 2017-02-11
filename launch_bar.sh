#!/bin/bash
PANEL_HEIGHT=22

bspc config top_padding $PANEL_HEIGHT

#-f "Roboto-10" -f "Koruri-10" -f "FontAwesome" -f "sm4tik" -f "ntrrgcbarfont" \
~/Programas/bar/lemonbar \
  -f "Roboto-10,Koruri-10,FontAwesome,sm4tik,ntrrgcbarfont" \
  -B '#000000' \
  -g 3840x$PANEL_HEIGHT \
  -u 2 -o -3 | bash
