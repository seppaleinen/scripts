#!/usr/bin/env bash

# Check inputs
[[ -z "$1" ]] && echo "You must provide a name to search for" && exit 1;
# Check that lynx is installed
command -v lynx &> /dev/null
[[ -s "$HOME/lynx.cfg" ]] || echo "No existing lynx.cfg file" && exit 1;

function searchPirateBay() {
	local QUERY="${1// /%20}";
	local URL="http://thepiratebay.se/search/$QUERY";
	local GREP1='magnet:';
	lynx -cfg=~/lynx.cfg "$URL" -dump | grep "$GREP1" | awk '{print $2}' >> "$TMPFILE"
}
function searchTorrentLeech() {
	local QUERY="${1// /%20}";
	local URL="http://www.torrentleech.org/torrents/browse/index/query/$QUERY";
	local GREP1='/download/';
	local GREP2='.torrent';
	lynx -cfg=~/lynx.cfg "$URL" -dump | grep "$GREP1" | grep "$GREP2" | awk '{print $2}' >> "$TMPFILE"
}
function searchKickass() {
	local QUERY="${1// /%20}";
	local URL="http://kickass.to/usearch/$QUERY";
	local GREP1='http://torcache.net/torrent/';
	local GREP2='.torrent';
	lynx -cfg=~/lynx.cfg "$URL" -dump | grep "$GREP1" | grep "$GREP2" | awk '{print $2}' >> "$TMPFILE"
}
function getTitle() {
	local TORRENT="$1";
	local SITE="$2";
	case $SITE in
		$KICKASS)
			echo "$TORRENT" | awk -F']' '{print $2}' | awk -F'.torrent' '{print $1}';
			;;
		$TORRENTLEECH)
			echo "$TORRENT" | awk -F'/' '{print $6}' | awk -F'.torrent' '{print $1}';
			;;
		$PIRATEBAY)
			echo "$TORRENT" | awk -F'=' '{print $3}' | tr '+' '.' | sed 's/%5B/[/g' | sed 's/%5D/]/g' | sed 's/&tr//g' ;
			;;
	esac
}
function showResult() {
	local KICKASS='kickass';
	local TORRENTLEECH='torrentleech';
	local PIRATEBAY='piratebay';
	local RESULT="$1";
	local ROW="$2";
	local KICKASS_TITLE;
	local TORRENTLEECH_TITLE;
	local PIRATEBAY_TITLE;
	KICKASS_TITLE=$( getTitle "$RESULT" "$KICKASS" );
	TORRENTLEECH_TITLE=$( getTitle "$RESULT" "$TORRENTLEECH" );
	PIRATEBAY_TITLE=$( getTitle "$RESULT" "$PIRATEBAY" );
	test "${RESULT#*$KICKASSDIVIDER}" != "$RESULT" && echo "$ROW KICKASS: $KICKASS_TITLE";
	test "${RESULT#*$TORRENTLEECHDIVIDER}" != "$RESULT" && echo "$ROW TORRENTLEECH: $TORRENTLEECH_TITLE";
	test "${RESULT#*$PIRATEBAYDIVIDER}" != "$RESULT" && echo "$ROW PIRATEBAY: $PIRATEBAY_TITLE";
}
function chooseTorrent() {
	local KICKASSDIVIDER='torcache'
	local TORRENTLEECHDIVIDER='http://www.torrentleech.org/download/'
	local PIRATEBAYDIVIDER='magnet:'
	local ROWS;
	ROWS=$( less "$TMPFILE" | wc -l )
	for (( i = 1; i <= ROWS; i++ ));
	do
	        local RESULT;
		RESULT=$( less "$TMPFILE" | sed -n "${i}p" );
		showResult "$RESULT" "$i";
	done
	if [[ ! $ROWS -eq 1 ]]; then
		echo "Choose a torrent by number"
		read -r INPUT
		if [[ ! -z "$INPUT" ]]; then
		        local link;
		        link=$( less "$TMPFILE" | sed -n "${INPUT}p" );
			open -a uTorrent "$link";
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