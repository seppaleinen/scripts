#!/bin/bash
#Bash strict-mode
set -euo pipefail

function getBrowser() {
        local LYNX
        local ELINKS
	LYNX=$( which lynx )
	ELINKS=$( which elinks )
	test -n "$LYNX" && echo "lynx"; exit 1;
	test -n "$ELINKS" && echo "elinks"; exit 1;
}
TIMES=0
function youtube() {
	TIMES=$(( TIMES + 1 ))
	local BROWSER
	BROWSER="$( getBrowser )"
	local MAXTIMES="$2";
	local YOUTUBEURL="$1"
	local YOUTUBETITLE
	YOUTUBETITLE=$( "$BROWSER" "$YOUTUBEURL" -source | grep '"eow-title"' | awk -F'title="' '{print $2}' | awk -F'">' '{print $1}' )
	$( echo $( $BROWSER "$YOUTUBEURL" -dump | grep 'watch?v=' | awk -F'. ' '{print $3}' ) | tr ' ' '\n' | grep -Ev 'android-app|ios-app' > /tmp/youtube )
	local MAX
	MAX=$( less /tmp/youtube | wc -l )
	local RAND=$(( ( RANDOM % MAX )  + 1 ))
	local RANDOMVIDEO
	RANDOMVIDEO=$( less '/tmp/youtube' | sed -n "${RAND}p" )
	printf "%s TITLE: $TIMES: $YOUTUBETITLE $YOUTUBEURL\\n" "$(tput setaf 2)"
	tput sgr0
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
