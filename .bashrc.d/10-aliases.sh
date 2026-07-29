# Shell aliases.

if command -v sudo >/dev/null 2>&1 && [ "$EUID" -ne 0 ]; then
    alias spico='sudo pico'
    alias snano='sudo nano'
    alias svi='sudo vi'
else
    unalias spico 2>/dev/null
    unalias snano 2>/dev/null
    unalias svi 2>/dev/null
fi

alias vim='nvim'
alias web='cd /var/www/html'
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
alias ebrc='edit "${DOTFILES_DIR:-$HOME/dotfiles}/.bashrc.d"'
alias hlp='less ~/.bashrc_help'
alias da='date "+%Y-%m-%d %A %T %Z"'
alias cp='cp -i'
alias mv='mv -i'
if command -v trash >/dev/null 2>&1; then
    alias rm='trash -v'
else
    unalias rm 2>/dev/null
fi
alias mkdir='mkdir -p'
alias ps='ps auxf'
alias ping='ping -c 10'
alias less='less -R'
alias cls='clear'
alias vi='nvim'
alias vis='nvim "+set si"'
alias multitail='multitail --no-repeat -c'
alias yayf="yay -Slq | fzf --multi --preview 'yay -Sii {1}' --preview-window=down:75% | xargs -ro yay -S"
alias home='cd ~'
alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias bd='cd "$OLDPWD"'
alias rmd='/bin/rm  --recursive --force --verbose '
alias la='ls -Alh'
alias ls='ls -aFh --color=always'
alias lx='ls -lXBh'
alias lk='ls -lSrh'
alias lc='ls -ltcrh'
alias lu='ls -lturh'
alias lr='ls -lRh'
alias lt='ls -ltrh'
alias lm='ls -alh |more'
alias lw='ls -xAh'
alias ll='ls -Fls'
alias labc='ls -lap'
alias lf="ls -l | egrep -v '^d'"
alias ldir="ls -l | egrep '^d'"
alias lla='ls -Al'
alias las='ls -A'
alias lls='ls -l'
alias mx='chmod a+x'
alias 000='chmod -R 000'
alias 644='chmod -R 644'
alias 666='chmod -R 666'
alias 755='chmod -R 755'
alias 777='chmod -R 777'
alias h="history | grep "
alias p="ps aux | grep "
alias topcpu="/bin/ps -eo pcpu,pid,user,args | sort -k 1 -r | head -10"
alias f="find . | grep "
alias countfiles="for t in files links directories; do echo \`find . -type \${t:0:1} | wc -l\` \$t; done 2> /dev/null"
alias checkcommand="type -t"
alias openports='netstat -nape --inet'
alias diskspace="du -S | sort -n -r |more"
alias folders='du -h --max-depth=1'
alias folderssort='find . -maxdepth 1 -type d -print0 | xargs -0 du -sk | sort -rn'
alias tree='tree -CAhF --dirsfirst'
alias treed='tree -CAFd'
alias mountedinfo='df -hT'
alias mktar='tar -cvf'
alias mkbz2='tar -cvjf'
alias mkgz='tar -cvzf'
alias untar='tar -xvf'
alias unbz2='tar -xvjf'
alias ungz='tar -xvzf'
alias sha1='openssl sha1'
alias clickpaste='sleep 3; xdotool type "$(xclip -o -selection clipboard)"'
alias kssh="kitty +kitten ssh"
alias docker-clean=' \
  docker container prune -f ; \
  docker image prune -f ; \
  docker network prune -f ; \
  docker volume prune -f '
alias hug="systemctl --user restart hugo"
alias lanm="systemctl --user restart lan-mouse"
