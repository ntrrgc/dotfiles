#!/bin/bash

# pad buttons from top to bottom, with the hardware button number they emit
PAD_1=1
PAD_2=9
PAD_3=8
PAD_4=3

STYLUS_BOTTOM=2
STYLUS_TOP=3

if xsetwacom --list devices | grep Finger > /dev/null; then
  xsetwacom --set "Wacom Bamboo 16FG 6x8 Finger touch" touch off
  xsetwacom --set "Wacom Bamboo 16FG 6x8 Finger touch" gesture off
else
  # https://bugzilla.redhat.com/show_bug.cgi?id=1249089
  xinput disable "Wacom Bamboo 16FG 6x8 Finger"
fi

if [ "$HOSTNAME" == "madoka" ]; then
  xsetwacom --set "Wacom Bamboo 16FG 6x8 Pen stylus" MapToOutput HEAD-0
  xsetwacom --set "Wacom Bamboo 16FG 6x8 Pen eraser" MapToOutput HEAD-0
fi

xsetwacom --set "Wacom Bamboo 16FG 6x8 Pad pad" Button $PAD_3 "key y"
xsetwacom --set "Wacom Bamboo 16FG 6x8 Pad pad" Button $PAD_4 "key z"

#xsetwacom --set "Wacom Bamboo 16FG 6x8 Pen stylus" Button $STYLUS_BOTTOM "key del"
