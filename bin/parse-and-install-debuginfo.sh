#!/bin/bash
# Fed this script with the output of `info sharedlibrary` in gdb.
# Be careful to remove the last line that explains what (*) means in the output.
set -eu
file="$1"
libs=()
mapfile -t libs < <(grep '(*)' < "$file" | sed 's|.*(*)\s\+||')
mapfile -t packages < <(printf "%s\n" "${libs[@]}" | xargs -n1 rpm -q --whatprovides)
sudo dnf debuginfo-install "${packages[@]}"
