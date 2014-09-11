#!/bin/bash

while getopts ":a:bc:" opt; do
	case $opt in
		a)
			echo "a: parameter: $OPTARG";
			;;
		b)
			echo "b: $OPTARG";
			;;
		c)
			echo "c: parameter: $OPTARG";
			;;
		\?)
			echo "invalid: $OPTARG";
			;;
		:)
			echo "$OPTARG requires an argument";
			;;
	esac
done