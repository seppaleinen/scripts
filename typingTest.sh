#!/usr/bin/env bash

declare -a WORDS_RIGHT;
declare -a WORDS_WRONG;
WORD_LIST=$( less /usr/share/dict/words | grep -Ev '[a-zA-Z]{8,}' );
MAX=$( echo $WORD_LIST | tr ' ' '\n' | wc -l )

function getRandomWord() {
	local RANDOM_NUMBER=$( awk "BEGIN{srand();print int(rand()*($MAX-1))+1 }" )
	echo $( echo $WORD_LIST | tr ' ' '\n' | sed -n "$RANDOM_NUMBER"p )
}
function startGame() {
	local START_TIME=$SECONDS;
	for i in {1..30}
	do
		local RANDOM_WORD=$( getRandomWord )
		echo $RANDOM_WORD;
		read WORD
		if [[ "$WORD" == "$RANDOM_WORD" ]]; then
			WORDS_RIGHT=("${WORDS_RIGHT[@]}" "$WORD")
		else
			WORDS_WRONG=("${WORDS_WRONG[@]}" "$WORD")
		fi
		clear
	done
	local END_TIME=$(( $SECONDS - $START_TIME ));
	echo "${#WORDS_RIGHT[@]} words right, ${#WORDS_WRONG[@]} words wrong in $END_TIME seconds"
}
clear
echo "When ready, press any key."
read INPUT;
clear
startGame