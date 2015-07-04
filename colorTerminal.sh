#!/bin/bash

#Test if stdout is terminal
if [[ -t 1 ]]; then
	red=$(tput setaf 1);
	green=$(tput setaf 2);
	reset=$(tput sgr0);
fi

#color the terminal and reset to normal
printf '%s[+] Converting files \n' "$green" "$reset"