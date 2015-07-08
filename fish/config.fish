set dotfiles_dir (dirname (status -f))
set -x PATH $dotfiles_dir $PATH

function s
    if test (count $argv) -lt 1
        sudo -s
    else
        sudo $argv
    end
end

if test -x /bin/pacman
    alias pas='sudo pacman -S'
    alias pass='sudo pacman -Ss'
    alias pai='pacman -iQ'
    alias par='sudo pacman -R'
    alias yas='yaourt -S --noconfirm'
    alias yass='yaourt -Ss'
    alias yolo='sudo pacman -Syu'
else
    alias pas='sudo apt-get install'
    alias pass='sudo apt-cache search'
    alias pai='apt-cache show'
    alias par='sudo apt-get purge'
    alias ll='ls -lh'
end

alias pgr='ps aux | grep'
alias sys='sudo systemctl'
alias clip='xclip -selection clipboard'
alias gs='git status'
alias ga='git add'
alias gp='git push'
alias dif='git diff'
alias grebase='git fetch ; and git rebase'
alias greset='git checkout --'
if test -x /usr/bin/journalctl
    alias logf='sudo journalctl -fl'
else
    alias logf='sudo tail -f /var/log/messages'
end
alias plusx='chmod +x'
function gc
    if test (count $argv) -lt 1
        git commit
    else
        git commit -m $argv
    end
end

alias l='ls'
