# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

DOTFILES_DIR=$( cd "$( dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd )

# Ideally this should be in ~/.profile, but this will make sure they will work in the shell at least.
. "$DOTFILES_DIR/exported-paths.sh"

# If not running interactively, don't do anything more
[ -z "$PS1" ] && return

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=10000
HISTFILESIZE=20000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

alias ll='ls -alFh'
alias la='ls -A'
alias l='ls -CF'
alias gvim='gvim 2> /dev/null' # ignore gtk errors
alias vi='vim'
alias python=python3
alias ipython=ipython3
alias pip=pip3
alias bt=build-type

# Convenient less settings for analyzing GStreamer logs:
# -R raw (allow format codes)
# -S no line wrapping
# #20 left and right keys move 20 characters at a time
alias le='less -SR#20'

function is_writable() {
  if [[ -f "$1" ]]; then
    # If the file already exists, return whether it is writable.
    [[ -w "$1" ]]
  else
    # If the file does not exist yet, return whether its directory is
    # writable and therefore the file can be created there.
    [[ -w "$(dirname "$1")" ]]
  fi
}

function vim() {
  # In Fedora, use X11-enabled Vim when possible (vimx), so that system clipboard is accessible.
  # Also, unset PYTHONHOME and PYTHONPATH unless told otherwise. Often third-party Python environments
  # mess up with installed Vim plugins.
  local env_prefix=""
  if [[ -z "${VIM_ALLOW_PYTHON_ENV:-}" ]]; then
    env_prefix="env --unset=PYTHONHOME --unset=PYTHONPATH"
  fi
  local vim_executable=($env_prefix "$(which vimx >/dev/null 2>&1 && echo "vimx" || echo "vim")")
  if [[ $# -eq 1 ]] && ! is_writable "$1"; then
    sudo "${vim_executable[@]}" "$@"
  else
    command "${vim_executable[@]}" "$@"
  fi
}

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
# Debian/Ubuntu:
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi
# Fedora
if [ -f /etc/profile.d/bash_completion.sh ] && ! shopt -oq posix; then
    . /etc/profile.d/bash_completion.sh
fi

# Needed so that the current directory is preserved across windows and tabs in
# some terminals.
if [ -f /etc/profile.d/vte.sh ]; then
  . /etc/profile.d/vte.sh
fi

function __try_paths() {
  for path in "$@"; do
    if [ -e "$path" ]; then
      echo "$path"
      return
    fi
  done
}

function s() {
  if [ $# -eq 0 ]; then
    exec sudo -s
  else
    sudo "$@"
  fi
}
function fname() {
  find . -iname '*'"$1"'*' "${@:2}" 2> /dev/null
}
function find-js-function() {
  # Find JavaScript function definition
  local expr="function\\s+$1\\(|\\.$1\\s*=|['\"]$1['\"]\\s*\]" 
  if [ "${2:-}" == "go" ]; then
    local IFS=$'\n'
    VIM_ARGS=($(rg --glob "!**/*.min.*" -n -tjs "${expr}" | python3 -c "$(cat <<'EOF'
#!/usr/bin/env python
import sys
files=[]
for line in sys.stdin:
  file, line = line.split(":")[:2]
  print(file)
  print("+" + line)
  sys.exit(0) # Vim does not support opening several files on several locations
EOF
)"))
    vim "${VIM_ARGS[@]}"
  else
    rg --glob "!**/*.min.*" -tjs "${expr}" "${@:2}"
  fi
}
if [ -x /bin/pacman ]; then
  alias pas='sudo pacman -S'
  alias pass='sudo pacman -Ss'
  alias pai='pacman -iQ'
  alias par='sudo pacman -R'
  alias yas='yaourt -S --noconfirm'
  alias yass='yaourt -Ss'
  alias yolo='sudo pacman -Syu'
elif [ -x /usr/bin/apt-get ]; then
  alias yolo='sudo apt-get update && sudo apt-get upgrade'
  alias pas='sudo apt-get install'
  alias pass='sudo apt-cache search'
  alias pai='apt-cache show'
  alias par='sudo apt-get purge'
elif [ -x /usr/bin/dnf ]; then
  alias yolo='sudo dnf upgrade -y'
  alias pas='sudo dnf install -y'
  alias pass='sudo dnf search'
  alias pai='sudo dnf info'
  alias par='sudo dnf remove'
elif [ -x /usr/bin/yum ]; then
  alias yolo='sudo yum upgrade -y'
  alias pas='sudo yum install -y'
  alias pass='sudo yum search'
  alias pai='sudo yum info'
  alias par='sudo yum remove'
fi

alias ll='ls -lh'
alias sys='sudo systemctl'
alias ipy='ipython3'
alias clone='git clone'
alias log='git log'
alias gs='git status'
alias ga='git add'
alias gp='git push'
alias dif='git diff'
alias grebase='git fetch && git rebase'
alias pull='git pull'
alias cherry='git cherry-pick'
alias greset='git checkout --'
alias co='git checkout'
function tmpb() {
  # Create a throwaway branch
  if [ $# -ne 1 ]; then
    echo "Usage: $0 <bug-name>"
    echo "Creates a temporary git branch with the current date and the name of the bug."
    return 1
  fi
  git checkout -b "$(date +%y-%m-%d)-$1"
}
alias tmpbr='echo git checkout -b $(date +%y-%m-%d)-$1'
alias sho='git show'
# Just In Case, stash unstaged changes so I can run clean test on what I'm about to commit
alias jic='git stash --keep-index --include-untracked'
alias spop='git stash pop'
if [ -x /usr/bin/journalctl ]; then
  alias logf='sudo journalctl -fl'
else
  alias logf='sudo tail -f /var/log/messages'
fi
alias ggrep='git grep --break --heading -p'
alias plusx='chmod +x'
alias rg='rg --colors path:style:bold --colors path:fg:green --colors line:style:bold --colors match:bg:yellow --colors match:style:nobold --colors match:fg:black --glob "!**/*.min.*"'
function go_to() {
  # Run the provided command (which should be ripgrep or a similar command
  # printing file names and line numbers) and open the file in the specified
  # line

  # Optionally the first argument may specify the desired match number
  if [[ "$1" =~ ^[0-9]+$ ]]; then
    line_number=$1
    shift
  else
    line_number=1
  fi

  match_line="$("$@" -n | head -n$line_number |tail -n1)"
  file_name="$(echo "$match_line" | cut -d: -f1)"
  line_number="$(echo "$match_line" | cut -d: -f2)"
  vim "$file_name" +$line_number
}
alias wmon='watchd-monitor'
alias wgetr='wget -rc --no-parent -nH'
function check_git_identity() {
  # git will automatically stop a commit without an identity, but I'd
  # rather get a more helpful message for it.
  if ! git config user.email >/dev/null || ! git config user.name >/dev/null; then
    echo "You forgot to set an identity git config file for this repository!"
    echo ""
    echo "To fix it, run: git config include.path ~/.git-identity-<profile>"
    echo ""
    echo "Alternatively, use the following shortcut function: grid <profile>"
    return 1
  fi
}
function grid() {
  local profiles=($(_grid_profile_list))
  if [[ "$#" -ne 1 ]]; then
    echo "Usage: grid <profile>"
    echo ""
    echo "Available profiles: $(join_by ", " "${profiles[@]}")"
    return 1
  fi
  local requested_profile="$1"
  if [[ " ${profiles[*]} " != *" $requested_profile "* ]]; then
    echo "Profile doesn't exist: $requested_profile"
    return 1
  fi
  git config include.path "$HOME/.git-identity-$requested_profile"
}
function _grid_profile_list() {
  for identity_file in "$HOME/.git-identity-"*; do
    local identity_name="${identity_file##*/.git-identity-}"
    if [[ "$identity_name" != *"-annex" ]]; then
      echo "$identity_name"
    fi
  done
}
function _grid_complete() {
  # Don't autocomplete more than one argument
  if [[ "${#COMP_WORDS[@]}" -gt 2 ]]; then
    COMPREPLY=()
    return
  fi
  COMPREPLY=($(compgen -W "$(_grid_profile_list)" "${COMP_WORDS[1]}"))
}
complete -F _grid_complete grid
alias amend=git commit --amend
function gc() {
  check_git_identity || return
  if [[ "$#" -eq 0 ]]; then
    git commit
  else
    git commit -m "$@"
  fi
}
function mangrep() {
  if [ ! $# -eq 2 ]; then
    echo "Example of usage: mangrep wget -r"
    return 1
  fi
  LESS="${LESS:-} -+I" man -P 'less -p "^       '"$2"'\>"' $1
}
function implode { # array to string, joined with a given delimiter
  local IFS="$1"; shift; echo "$*"; 
}

export DJANGO=$(__try_paths \
  /usr/local/lib/python2.7/site-packages/django \
  /usr/local/lib/python2.7/dist-packages/django \
  /usr/lib/python2.7/site-packages/django \
  /usr/lib/python2.7/dist-packages/django \
)
function cmkdir() {
    mkdir "$1" && cd "$1"
}
function gvim() {
    (/usr/bin/gvim -f "$@" &)
}
function ppa() {
  sudo apt-add-repository "$1"
  sudo apt-get update
  sudo apt-get install -y "$2"
}
function ts-install() {
    tsd query "$1" --action install --save
}
function cmbuild() {
  mkdir -p "$1"
  PROJECT_DIR="$PWD"
  cd "$1"
  cmake "${@:2}" ..
}
function download_time() {
  qalc "($1Byte) / (${2:-120 k}Byte/s) to hours"
}
function join_by { 
  # https://stackoverflow.com/a/17841619/1777162
  local d=$1
  shift
  echo -n "$1"
  shift
  printf "%s" "${@/#/$d}"
}
function debug-web-process() {
  env WEB_PROCESS_CMD_PREFIX='/usr/bin/gdbserver localhost:9080' "$@"
}

shopt -s autocd
shopt -s histappend
export DROPBOX="$HOME/Dropbox"

if which ack-grep > /dev/null 2>&1; then
  alias ack='ack-grep'
fi

COLOR_RESET="\[\e[m\]"
COLOR_RESET_NO_PS="\e[m"
COLOR_GREEN="\[\e[38;5;$((24+88))m\]"
COLOR_YELLOW="\[\e[38;5;$((178))m\]"
COLOR_BLUE="\[\e[38;5;$((22+52))m\]"
COLOR_RED="\[\e[38;5;$((196+7))m\]"
COLOR_RED_NO_PS="\e[38;5;$((196+7))m"
COLOR_ORANGE="\[\e[38;5;$((196+12))m\]"
COLOR_CYAN="\[\e[38;5;$((29+124))m\]"

case "${HOSTNAME/.*}" in
  chuches)
    COLOR_HOST="\[\e[38;5;210m\]"
    ;;
  cati)
    COLOR_HOST="\[\e[38;5;178m\]"
    ;;
  potato)
    COLOR_HOST="\[\e[38;5;130m\]"
    ;;
  buildbox*)
    COLOR_HOST="\[\e[38;5;10m\]"
    ;;
  homura)
    COLOR_HOST="\[\e[38;5;249m\]"
    ;;
  mami)
    COLOR_HOST="\[\e[38;5;184m\]"
    ;;
  raspberrypi)
    COLOR_HOST="\[\e[38;5;133m\]"
    ;;
  rufian)
    COLOR_HOST="\[\e[38;5;185m\]"
    ;;
  *)
    COLOR_HOST="\[\e[38;5;37m\]"
    ;;
esac

PS_CHROOT="${debian_chroot:+${COLOR_ORANGE}(${debian_chroot}) }"
PS_TIME="${COLOR_GREEN}[\$(date +%k:%M:%S)]${COLOR_RESET}"
PS_PWD="${COLOR_BLUE}\w${COLOR_RESET}"
PS_USER="${COLOR_HOST}\u@\h${COLOR_RESET}"
PS_STAR="${COLOR_ORANGE}$(echo -ne '\xe2\x98\x85')${COLOR_RESET}"
PS_SNOW="${COLOR_CYAN}$(echo -ne '\xe2\x9d\x85')${COLOR_RESET}"

function _ps1_project_build_type() {
  local git_root="$(git rev-parse --show-toplevel 2> /dev/null)"
  if [[ ! -z "$git_root" ]]; then
    local build_type="$(cat "$git_root/.git/build-type" 2> /dev/null)"
    case "$build_type" in
      debug)
	echo -e " \e[38;5;205;1m[Debug]\033[22m"
	;;
      release)
	echo -e " \e[38;5;39;1m[Release]\033[22m"
	;;
      "")
	;; # No build type set for this repository
      *)
	echo -e " \e[48;5;196;1m[Invalid .git/build-type]\033[22;49m"
	;;
    esac
  fi
}

function _ps1_git_branch() {
  # Adapted from:
  # https://coderwall.com/p/fasnya/add-git-branch-name-to-bash-prompt
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* (\?\([^)]*\?\))\?$/ (\1)/'
}

PS1="${PS_CHROOT}${PS_TIME} ${PS_PWD}\$(_ps1_project_build_type)${COLOR_YELLOW}\$(_ps1_git_branch)
${PS_USER}${COLOR_HOST}❯ ${COLOR_RESET}"

# Use this technique to show the running command in the tab title:
# https://jichu4n.com/posts/debug-trap-and-prompt_command-in-bash/
function __pre_command() {
  if [[ "$PS_AT_PROMPT" == false ]]; then
    return
  fi

  PS_AT_PROMPT=false
  echo -ne "\033]2;$(history 1 | sed "s/^[ ]*[0-9]*[ ]*//g")\007"
}

PS_FIRST_TIME=true
PS_AT_PROMPT=false
function __prompt_command() {
  # Save the return code of the program the user just run
  local ret=$?

  # Save history ASAP, but do not load it, so that the arrow keys always give
  # the latest command of this particular tab.
  history -a

  # We may be overriding __vte_prompt_command, which is also set as 
  # PROMPT_COMMAND and is responsible from informing the terminal emulator
  # what directory we're in and showing "Command complete" alerts.
  # If that's the case, invoke it here.
  if type -t __vte_prompt_command 2> /dev/null > /dev/null; then
    __vte_prompt_command
  else
    # Otherwise, let's do it ourselves (code adapted from Fedora's /etc/profile.d/vte.sh)
    local chroot_prefix=""
    if [ "${debian_chroot:-}" != "" ]; then
        chroot_prefix="($debian_chroot) "
    fi
    local command=$(HISTTIMEFORMAT= history 1 | sed 's/^ *[0-9]\+ *//')
    local command="${command//;/ }"
    local pwd='~'
    [ "$PWD" != "$HOME" ] && pwd=${PWD/#$HOME\//\~\/}

    local notif_title="${chroot_prefix}Command completed"
    local notif_body="${command}"

    __emit_desktop_notification "$notif_title" "$notif_body"
    __set_terminal_title "$USER@${HOSTNAME%%.*}:$pwd"
    if [ "$TERM" == "xterm-kitty" ]; then
      builtin printf "\e]7;kitty-shell-cwd://%s%s\a" "$HOSTNAME" "$PWD"
    fi
  fi

  if $PS_FIRST_TIME; then
    PS_FIRST_TIME=false
  else
    # Show return code of previous command
    if [[ $ret != 0 ]]; then
      echo -e "${COLOR_RED_NO_PS}exited with code $ret ✘ ${COLOR_RESET_NO_PS}"
    fi

    # Print always a newline except if it's the first line
    echo
  fi
  PS_AT_PROMPT=true
}

function __emit_desktop_notification() {
  # There are several competing protocols for desktop notifications:
  # https://github.com/gdamore/tcell/issues/499
  local title=$1
  local body=$2
  # Note (because I will forget): \033\\ means ST (String Terminator), which ends an OSC.

  if [ "${TERM}" == "xterm-kitty" ]; then
    # https://github.com/kovidgoyal/kitty/blob/master/docs/desktop-notifications.rst
    printf '\033]99;i=1:d=0:p=title:e=1;%s\033\\' "$(echo -n "$title" |base64 -)"
    printf '\033]99;i=1:d=0:p=body:e=1;%s\033\\' "$(echo -n "$body" |base64 -)"
    printf '\033]99;i=1:d=1:o=invisible:a=focus;\033\\'
  else
    # OSC 777 (e.g. VTE)
    printf '\033]777;notify;%s;%s\033\\' "$title" "$body"
  fi
}

function __set_terminal_title() {
  local title=$1
  printf '\033]0;%s\033\\' "$title"
}

# Update the PS1 variable after each command (and also shows exit codes)
PROMPT_COMMAND='__prompt_command'

trap '__pre_command' DEBUG

# http://stackoverflow.com/a/23710535/1777162
cl() { history -p '!!'|tr -d \\n|clip; }

. h.sh

# I get tired of typing the same paths over and over
alias app="cd ~/Apps"
alias gst="cd ~/Apps/gstreamer"
alias good="cd ~/Apps/gstreamer/subprojects/gst-plugins-good"
alias bad="cd ~/Apps/gstreamer/subprojects/gst-plugins-bad"
alias dotfiles="cd ~/dotfiles"
alias ytjs="cd ~/Apps/js_mse_eme"
alias media="cd ~/Apps/js_mse_eme/media"
alias wk='cd $(find-webkit.sh)'
alias tests='cd $(find-webkit.sh)/LayoutTests'
alias wkgst='cd $(find-webkit.sh)/Source/WebCore/platform/graphics/gstreamer'
alias mse='cd $(find-webkit.sh)/Source/WebCore/platform/graphics/gstreamer/mse'
alias amse='cd $(find-webkit.sh)/Source/WebCore/Modules/mediasource'
alias spad="cd /home/ntrrgc/Dropbox/tmp/gst-print-mkv-duration"
alias bpad="cd /home/ntrrgc/Dropbox/tmp/build-gst-print-mkv-duration-Desktop_*"
alias gstb="ninja -C ~/Apps/gstreamer/builddir"
alias gstu="~/Apps/gstreamer/gst-env.py"
alias backup="~/Dropbox/backup-pc.sh"

function mam() {
  if ([[ $# -eq 1 ]] && [[ "$1" == "--help" ]]) || [[ $# -gt 1 ]]; then
    echo "Usage: mam [env]"
    echo "Sources the micromamba shell hook (will shadow other Python environments like pyenv) and activates the environment with name [env]."
    echo "If [env] is not provided, the root environment (base) is activated."
    return
  fi
  env_name="base"
  if [[ $# -gt 0 ]]; then
    env_name="$1"
  fi
  export MAMBA_ROOT_PREFIX="${MAMBA_ROOT_PREFIX:-$HOME/Apps/mamba-root-prefix}"
  eval "$(micromamba shell hook --shell bash)"
  micromamba activate "$env_name"
}

if [ -f "$HOME/.bashrc_local" ]; then
  . "$HOME/.bashrc_local"
fi

# Don't capture <C-S>
# I'd rather use it as a hotkey in Vim that have it suspend the terminal.
stty stop undef


# Undefine variables set by Debian bashrc (above)... currently they are unused,
# but they should be read in order to know if colors should be omitted in PS1
unset color_prompt force_color_prompt

if [ -f ~/.cargo/env ]; then
  . "$HOME/.cargo/env"
fi

in_wkdev_sdk=$([ ! -d /wkdev-sdk ]; echo $?)
if [ $in_wkdev_sdk -eq 0 ] && [ -d ~/Apps/pyenv ]; then
  export PYENV_ROOT="$HOME/Apps/pyenv"
  command -v pyenv >/dev/null || register_path PATH "$PYENV_ROOT/bin"
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
fi

if [ -d ~/Apps/wkdev-sdk ]; then
  pushd ~/Apps/wkdev-sdk &>/dev/null
  source ./register-sdk-on-host.sh
  popd &>/dev/null
fi

# I often use this variable in GST_DEBUG
all_tracers=$(join_by , {GST_{PADS,BUFFER{,_LIST},EVENT,MESSAGE,ELEMENT_{FACTORY,PADS},STATES},query,bin}:TRACE)
