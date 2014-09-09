START_INDEX=1;
END_INDEX=3;
declare -a WORDS_RIGHT;
declare -a WORDS_WRONG;

function getRandomWord() {
	local RANDOM_NUMBER=$( awk 'BEGIN{srand();print int(rand()*(235886-1))+1 }' )
	echo $( less /usr/share/dict/words | sed -n "$RANDOM_NUMBER"p )
}
function startGame() {
	local START_TIME=$SECONDS;
	for i in {1..3}
	do
		local RANDOM_WORD=$( getRandomWord )
		echo $RANDOM_WORD;
		read WORD
		if [[ "$WORD" == "$RANDOM_WORD" ]]; then
			WORDS_RIGHT=("${WORDS_RIGHT[@]}" "$WORD")
		else
			WORDS_WRONG=("${WORDS_WRONG[@]}" "$WORD")
		fi
	done
	local END_TIME=$(( $SECONDS - $START_TIME ));
	echo "${#WORDS_RIGHT[@]} words right, ${#WORDS_WRONG[@]} words wrong in $END_TIME seconds"
}

echo "When ready, press any key."
read INPUT;
startGame