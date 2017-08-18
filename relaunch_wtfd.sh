#!/bin/bash

# Kill previous instance
pkill wtfd.py
pkill -f "nc -U /tmp/wtfd-pub.sock"

# Launch a new one in the background
nohup bash -c "~/dotfiles/wtfd.py 2> /tmp/wtfd-error.log | nc -U /tmp/wtfd-pub.sock"  > /dev/null 2>&1 &
