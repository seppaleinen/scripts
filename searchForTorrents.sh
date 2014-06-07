function searchPirateBay() {
	local QUERY="$( echo "$1" | sed 's/ /%20/g' )"
	local URL="http://thepiratebay.se/search/$QUERY"
	local GREP1='magnet:'
	lynx -cfg=~/lynx.cfg "$URL" -dump | grep "$GREP1" | awk '{print $2}' >> $TMPFILE
}
function searchTorrentLeech() {
	local QUERY="$( echo "$1" | sed 's/ /%20/g' )"
	local URL="http://www.torrentleech.org/torrents/browse/index/query/$QUERY"
	local GREP1='/download/'
	local GREP2='.torrent'
	lynx -cfg=~/lynx.cfg "$URL" -dump | grep "$GREP1" | grep "$GREP2" | awk '{print $2}' >> $TMPFILE
}
function searchKickass() {
	local QUERY="$( echo "$1" | sed 's/ /%20/g' )"
	local URL="http://kickass.to/usearch/$QUERY"
	local GREP1='http://torcache.net/torrent/'
	local GREP2='.torrent'
	lynx -cfg=~/lynx.cfg "$URL" -dump | grep "$GREP1" | grep "$GREP2" | awk '{print $2}' >> $TMPFILE
}
function getTitle() {
	local TORRENT="$1"
	local SITE="$2"
	case $SITE in
		$KICKASS)
			echo $TORRENT | awk -F']' '{print $2}' | awk -F'.torrent' '{print $1}';
			;;
		$TORRENTLEECH)
			echo $TORRENT | awk -F'/' '{print $6}' | awk -F'.torrent' '{print $1}';
			;;
		$PIRATEBAY)
			echo $TORRENT | awk -F'=' '{print $3}' | tr '+' '.' | sed 's/%5B/[/g' | sed 's/%5D/]/g' | sed 's/&tr//g' ;
			;;
	esac	
}
function showResult() {
	local KICKASS='kickass'
	local TORRENTLEECH='torrentleech'
	local PIRATEBAY='piratebay'
	local RESULT="$1"
	local ROW="$2"
	test "${RESULT#*$KICKASSDIVIDER}" != "$RESULT" && echo $ROW KICKASS: $(getTitle "$RESULT" "$KICKASS" )
	test "${RESULT#*$TORRENTLEECHDIVIDER}" != "$RESULT" && echo $ROW TORRENTLEECH: $(getTitle "$RESULT" "$TORRENTLEECH" )
	test "${RESULT#*$PIRATEBAYDIVIDER}" != "$RESULT" && echo $ROW PIRATEBAY: $(getTitle "$RESULT" "$PIRATEBAY" )
}
function chooseTorrent() {
	local KICKASSDIVIDER='torcache'
	local TORRENTLEECHDIVIDER='http://www.torrentleech.org/download/'
	local PIRATEBAYDIVIDER='magnet:'
	local ROWS="$( less $TMPFILE | wc -l )"
	for (( i = 1; i <= $ROWS; i++ ));
	do
		local RESULT="$( less $TMPFILE | sed -n "$( echo $i )p" )"
		showResult "$RESULT" "$i"
	done
	if [[ ! $ROWS -eq 1 ]]; then
		echo "Choose a torrent by number"
		read INPUT
		if [[ ! -z "$INPUT" ]]; then
			open -a uTorrent "$( less $TMPFILE | sed -n "$( echo $INPUT )p" )"
		fi
	else
		echo "No results!"
	fi
	rm -f "$TMPFILE"
}
function searchTorrents() {
	local QUERY="$1"
	TMPFILE='/tmp/searchTorrent'
	echo > "$TMPFILE"
	searchTorrentLeech "$QUERY"
	searchKickass "$QUERY"
	searchPirateBay "$QUERY"
	chooseTorrent
}
searchTorrents "$1"