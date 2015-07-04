#!/bin/bash
#Bash strict-mode
set -euo pipefail

function getBrowser() {
	local LYNX=$( which lynx )
	local ELINKS=$( which elinks )
	test -n "$LYNX" && echo "lynx"; exit 1;
	test -n "$ELINKS" && echo "elinks"; exit 1;
}
TIMES=0
function youtube() {
	local TIMES=$(( $TIMES + 1 ))
	local BROWSER="$( getBrowser )"
	local MAXTIMES="$2";
	local YOUTUBEURL="$1"
	test -z "$YOUTUBEURL" && exit;
	local YOUTUBETITLE=$( $BROWSER "$YOUTUBEURL" -source | grep '"eow-title"' | awk -F'title="' '{print $2}' | awk -F'">' '{print $1}' )
	local RECOMMENDEDVIDEOS=$( echo $( $BROWSER "$YOUTUBEURL" -dump | grep 'watch?v=' | awk -F'. ' '{print $3}' ) | tr ' ' '\n' > /tmp/youtube )
	local MAX=$( less /tmp/youtube | wc -l )
	local RAND=$(( ( RANDOM % MAX )  + 1 ))
	local RANDOMVIDEO=$( less '/tmp/youtube' | sed -n "$(echo $RAND)p" )
	test -z "$RANDOMVIDEO" && exit;
	echo TITLE "$TIMES": "$YOUTUBETITLE" "$YOUTUBEURL"
	if [[ $MAXTIMES != 0 && $MAXTIMES -eq $TIMES ]]; then
		open "$YOUTUBEURL"
		exit;
	fi
	youtube "$RANDOMVIDEO" "$MAXTIMES"
}

#Default-values
readonly URL="${1:-www.youtube.com}"
readonly MAX_TIMES="${2:-1000}"
youtube "$URL" "$MAX_TIMES"
