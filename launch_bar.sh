#!/bin/bash
PANEL_HEIGHT=22

bspc config top_padding $PANEL_HEIGHT

~/Programas/bar/lemonbar \
  -f "ntrrgcbarfont,FontAwesome,Roboto-10,IPAGothic-11,sm4tik" \
  -B '#000000' \
  -g 3840x$PANEL_HEIGHT \
  -u 2 -o -3 | bash
