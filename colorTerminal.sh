#!/bin/bash

#Test if stdout is terminal
if [[ -t 1 ]]; then
	red=$(tput setaf 1);
	green=$(tput setaf 2);
	brown=$(tput setaf 3);
	purple=$(tput setaf 4);
	pink=$(tput setaf 5);
	blue=$(tput setaf 6);
	reset=$(tput sgr0);
fi

#color the terminal and reset to normal
printf '%s[+] Converting files \n' "$brown"
printf '%s[+] Converting files \n' "$purple"
printf '%s[+] Converting files \n' "$pink"
printf '%s[+] Converting files \n' "$blue"
printf '%s[+] Converting files \n' "$green" "$reset"