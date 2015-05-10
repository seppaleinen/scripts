#!/bin/bash

function logic(){
	local cmd=$1
	local i=$2
	T="$(date +%s)";
	$( eval "$cmd" > /dev/null 2>&1 );
	T="$(($(date +%s)-T))";
	echo "The command: \"$cmd\" took $T seconds on the $i:th try";
}

function time_func(){
	local cmd="$1"
	for i in {1..5}; do 
		logic "$cmd" $i;
	done
}

time_func "$1"