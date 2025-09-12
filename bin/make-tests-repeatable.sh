#!/bin/bash
# Makes the computer slower, but more consistent, so that test result times can be more reliably compared.
# Implements ideas from: https://easyperf.net/blog/2019/08/02/Perf-measurement-environment-on-Linux
set -eu

is_undo=no
show_usage=no
for arg in "$@"; do
  case "$arg" in
    --undo)
      is_undo=yes
      ;;
    *)
      show_usage=yes
  esac
done
if [[ "$show_usage" == "yes" ]]; then
  echo "$(basename "$0") [--undo]"
  echo
  echo "Makes the computer slower, but more consistent, so that test result times can be more reliably compared."
fi

function choose() {
  val_if_not_undo="$1"
  val_if_undo="$2"
  if [[ "$is_undo" == "yes" ]]; then
    echo "$val_if_undo"
  else
    echo "$val_if_not_undo"
  fi
}

# Disable turboboost (AMD)
(echo $(choose 0 1) > /sys/devices/system/cpu/cpufreq/boost) || (echo $(choose 1 0) > /sys/devices/system/cpu/intel_pstate/no_turbo)

# Disable hyper threading
if [[ "$is_undo" == no ]]; then
  non_main_cpus=($(cat /sys/devices/system/cpu/cpu*/topology/thread_siblings_list |grep ,|cut -d, -f2 |sort -n|uniq))
  for cpu in "${non_main_cpus[@]}"; do
    echo 0 > "/sys/devices/system/cpu/cpu${cpu}/online"
  done
else
  for cpu in $(ls -1 /sys/devices/system/cpu |grep "cpu[0-9]\+$"); do
    if [[ "$cpu" != "cpu0" ]]; then  # cpu0 is always online
      echo 1 > "/sys/devices/system/cpu/${cpu}/online"
    fi
  done
fi

# Set scaling_governor to ‘performance’
for cpu in $(ls -1 /sys/devices/system/cpu |grep "cpu[0-9]\+$"); do
  # cpu0 is always online
  if [[ "$cpu" == "cpu0" ]] || [[ "$(cat "/sys/devices/system/cpu/$cpu/online")" -eq 1 ]]; then
    echo performance > "/sys/devices/system/cpu/$cpu/cpufreq/scaling_governor"
    cat "/sys/devices/system/cpu/$cpu/cpufreq/$(choose scaling_min_freq cpuinfo_max_freq)" > "/sys/devices/system/cpu/$cpu/cpufreq/scaling_max_freq"
  fi
done

# Isolate a few CPUs for sole use of the program being tested
# To take advantage of this, run the test program like this: tuna run --cpus=2 'stress -c 4'
isolated_cpus=4-7
if [[ "$is_undo" == no ]]; then
  tuna isolate --cpus="$isolated_cpus"
  printf "%s" "$isolated_cpus" >/tmp/isolated_cpus
else
  tuna include --cpus="$isolated_cpus"
fi
