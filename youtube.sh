function getBrowser() {
	local LYNX=$( which lynx )
	local ELINKS=$( which elinks )
	test ! -z "$LYNX" && echo "lynx"; exit 1;
	test ! -z "$ELINKS" && echo "elinks"; exit 1;
}
function youtube() {
	if [[ -z "$3" ]]; then
		TIMES=1;
	else
		TIMES=$(( TIMES + 1 ))
	fi
	BROWSER="$( getBrowser )"
	MAXTIMES="$2";
	YOUTUBEURL="$1"
	YOUTUBEDIVIDER='watch?v='
	YOUTUBEID=$( echo $YOUTUBEURL | sed 's/"$YOUTUBEDIVIDER"/ /g' | awk '{print $2}' )
	YOUTUBETITLE=$( $BROWSER "$YOUTUBEURL" -source | grep '"eow-title"' | awk -F'title="' '{print $2}' | awk -F'">' '{print $1}' )
	RECOMMENDEDVIDEOS=$( echo $( $BROWSER "$YOUTUBEURL" -dump | grep "$YOUTUBEDIVIDER" | awk -F'. ' '{print $3}' ) | tr ' ' '\n' > /tmp/youtube )
	MAX=$( less /tmp/youtube | wc -l )
	RAND=$( jot -r 1 1 $MAX )
	RANDOMVIDEO=$( less '/tmp/youtube' | sed -n "$(echo $RAND)p" )
	if [[ -z "$YOUTUBEURL" ]]; then
		exit;
	fi
	echo TITLE $TIMES: $YOUTUBETITLE $YOUTUBEURL
	if [[ $MAXTIMES != 0 && $MAXTIMES -eq $TIMES ]]; then
		open "$YOUTUBEURL"
		exit;
	fi
	youtube "$RANDOMVIDEO" "$MAXTIMES" "$TIMES"
}
youtube "$1" "$2"