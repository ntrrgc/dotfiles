#!/bin/bash

# Pause temporarily a process once every while.
# Used with extraodinarily long operations that could overheat external disks
# (e.g. dd'ing an entire multi-TiB disk).

set -eu

TARGET_PID="$1"
get_cmdline() {
  cat /proc/$TARGET_PID/cmdline | sed 's|\x00| |g'
}

PROCESS_CMDLINE="$(get_cmdline)"

while true; do
  sleep 60m
  if [[ "$PROCESS_CMDLINE" != "$(get_cmdline || true)" ]]; then
    echo "$(date): Target process has already finished."
    exit 0
  fi

  # Stop process
  kill -STOP $TARGET_PID
  echo "$(date): Stopped process."

  sleep 20m

  # Resume process
  kill -CONT $TARGET_PID
  echo "$(date): Resumed process."
done
