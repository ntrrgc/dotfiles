# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
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

# some more ls aliases
alias ll='ls -alFh'
alias la='ls -A'
alias l='ls -CF'
alias gvim='gvim 2> /dev/null' # ignore gtk errors
alias vi='vim'

# In Fedora, use X11-enabled Vim when possible, so that system clipboard is accessible
if which vimx > /dev/null 2>&1; then
  alias vim='vimx'
fi

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
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
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
function fjsf() {
  # Find JavaScript function definition
  local expr="function\\s+$1\\(|\\.$1\\s*=|['\"]$1['\"]\\s*\]" 
  if [ "${2:-}" == "go" ]; then
    local IFS=$'\n'
    VIM_ARGS=($(ag --js "${expr}" | python3 -c "$(cat <<'EOF'
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
    ag --js "${expr}" "${@:2}"
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
alias pgr='ps aux | grep'
alias sys='sudo systemctl'
alias clip='xclip -selection clipboard'
alias clone='git clone'
alias gs='git status'
alias ga='git add'
alias gp='git push'
alias dif='git diff'
alias grebase='git fetch && git rebase'
alias pull='git pull'
alias greset='git checkout --'
# Just In Case, stash unstaged changes so I can run clean test on what I'm about to commit
alias jic='git stash --keep-index --include-untracked'
alias spop='git stash pop'
if [ -x /usr/bin/journalctl ]; then
  alias logf='sudo journalctl -fl'
else
  alias logf='sudo tail -f /var/log/messages'
fi
alias plusx='chmod +x'
alias wmon='watchd-monitor'
alias wgetr='wget -rc --no-parent -nH'
alias amend='git commit --amend'
function gc() {
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
  man -P 'less -p "^       '"$2"'"' $1
}
function topath() {
  export PATH="$1:$PATH"
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
shopt -s autocd
shopt -s histappend
export DROPBOX="$HOME/Dropbox"

if which ack-grep > /dev/null 2>&1; then
  alias ack='ack-grep'
fi

COLOR_RESET="\[\e[m\]"
COLOR_RESET_NO_PS="\e[m"
COLOR_GREEN="\[\e[38;5;$((24+88))m\]"
COLOR_YELLOW="\[\e[38;5;$((196+32))m\]"
COLOR_BLUE="\[\e[38;5;$((22+52))m\]"
COLOR_RED="\[\e[38;5;$((196+7))m\]"
COLOR_RED_NO_PS="\e[38;5;$((196+7))m"
COLOR_ORANGE="\[\e[38;5;$((196+12))m\]"
COLOR_CYAN="\[\e[38;5;$((29+124))m\]"

PS_CHROOT="${debian_chroot:+${COLOR_ORANGE}(${debian_chroot}) }"
PS_TIME="${COLOR_GREEN}[\$(date +%k:%M:%S)]${COLOR_RESET}"
PS_PWD="${COLOR_BLUE}\w${COLOR_RESET}"
PS_USER="${COLOR_YELLOW}\u@\h${COLOR_RESET}"
PS_STAR="${COLOR_ORANGE}$(echo -ne '\xe2\x98\x85')${COLOR_RESET}"
PS_SNOW="${COLOR_CYAN}$(echo -ne '\xe2\x9d\x85')${COLOR_RESET}"

function __update_ps1() {
  PS1="${PS_CHROOT}${PS_TIME} ${PS_PWD}
${PS_USER}${COLOR_BLUE}❯ ${COLOR_RESET}"
}

PS_FIRST_TIME=true
function __prompt_command() {
  # Save the return code of the program the user just run
  local ret=$?

  # We may be overriding __vte_prompt_command, which is also set as 
  # PROMPT_COMMAND and is responsible from informing the terminal emulator
  # what directory we're in. If that's the case, invoke it here.
  if type -t __vte_prompt_command 2> /dev/null > /dev/null; then
    __vte_prompt_command
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

  __update_ps1
}

# Set the PS1 variable now
__update_ps1

# Update the PS1 variable after each command (and also shows exit codes)
PROMPT_COMMAND='__prompt_command'

# http://stackoverflow.com/a/23710535/1777162
cl() { history -p '!!'|tr -d \\n|clip; }

DOTFILES_DIR=$( cd "$( dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd )
export PATH="$PATH:$DOTFILES_DIR/bin"

if [ -f "$HOME/.bashrc_local" ]; then
  . "$HOME/.bashrc_local"
fi

# Don't capture <C-S>
# I'd rather use it as a hotkey in Vim that have it suspend the terminal.
stty stop undef


# Undefine variables set by Debian bashrc (above)... currently they are unused,
# but they should be read in order to know if colors should be omitted in PS1
unset color_prompt force_color_prompt
