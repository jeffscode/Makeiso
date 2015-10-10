#
# /etc/bash.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

PS1='[\u@\h \W]\$ '
PS2='> '
PS3='> '
PS4='+ '

case ${TERM} in
  xterm*|rxvt*|Eterm|aterm|kterm|gnome*)
    PROMPT_COMMAND=${PROMPT_COMMAND:+$PROMPT_COMMAND; }'printf "\033]0;%s@%s:%s\007" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/\~}"'

    ;;
  screen)
    PROMPT_COMMAND=${PROMPT_COMMAND:+$PROMPT_COMMAND; }'printf "\033_%s@%s:%s\033\\" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/\~}"'
    ;;
esac

[ -r /usr/share/bash-completion/bash_completion   ] && . /usr/share/bash-completion/bash_completion


# [[ -z $DISPLAY && $XDG_VTNR -eq 1  ]] && exec startx

alias s=startx
alias t=lxterminal
alias g=gparted
alias p=parted
alias f=fdisk
alias apg='less /root/partition'
alias aig='less /root/install.txt'
alias awd=dillo
alias awl='lynx https://wiki.archlinux.org/'
alias krp=killrp
alias rkb='clear && cat /root/ratinfo'
alias mst='clear && cat /usr/bin/minstall'
alias inf='clear && cat /root/startmessage'
