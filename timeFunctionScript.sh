#!/bin/bash

#Do command, and echo the time it takes to perform
function logic(){
	local cmd=$1
	local i=$2
	T="$(date +%s)";
	$( eval "$cmd" > /dev/null 2>&1 );
	T="$(($(date +%s)-T))";
	echo "The command: \"$cmd\" took $T seconds on the $i:th try";
}

#Loop through logic 5 times.
function time_func(){
	local cmd="$1"
	for i in {1..5}; do 
		logic "$cmd" $i;
	done
}

if [[ "x$1" == x ]]; then
	echo "You must enter a valid command enclosed in quotations";
else
	time_func "$1"
fi