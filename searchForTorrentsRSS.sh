function checkTorrentDay() {
	echo '***********************'
	echo "Checking torrentday for $( echo $SEARCHPARAMETERS | sed 's/\|/, /g' )"
	echo '***********************'
	URL='http://www.torrentday.com/torrents/rss?l12;l29;l22;l25;l11;l3;l13;l1;l17;l4;l24;l14;l7;l2;u=663487;tp=1f1532bd6f1c758b9ac5a435ed6d5104'
	TMPFILETORRENTDAY='/tmp/torrentday'
	curl -s "$URL" | gunzip | xmllint --format - | grep -E '<title>|<link>' > "$TMPFILETORRENTDAY"
	TITLEROWS=$( less "$TMPFILETORRENTDAY" | grep '<title>' | grep -n -i -E "$SEARCHPARAMETERS" | awk -F':' '{print $1}' )
	for TITLEROW in ${TITLEROWS[@]}
	do
			TITLE=$( less "$TMPFILETORRENTDAY" | grep '<title>' | sed -n "$( echo "$TITLEROW" )p" | awk -F'<title>' '{print $2}' | awk -F'</title>' '{print $1}' )
			LINK=$( less "$TMPFILETORRENTDAY" | grep '<link>' | sed -n "$( echo "$TITLEROW" )p" | awk -F'<link>' '{print $2}' | awk -F'</link>' '{print $1}' )
			echo FOUND $TITLE
			echo "TORRENTTITLE: $TITLE" >> $TMPFILE
			echo "TORRENTLINK: $( lynx -cfg=~/lynx.cfg $LINK -dump -nonumbers | grep download.php )" >> $TMPFILE
	done
	rm -f "$TMPFILETORRENTDAY"
}
function checkTorrentLeech() {
	echo '***********************'
	echo "Checking torrentleech for $( echo $SEARCHPARAMETERS | sed 's/\|/, /g' )"
	echo '***********************'
	TMPFILETORRENTLEECH='/tmp/torrentleech'
	TORRENTLEECHURL='http://rss.torrentleech.org/b85b149572368fb3e9c4'
	curl -s "$TORRENTLEECHURL" | xmllint --format - | grep -E '<title>|<link>' > "$TMPFILETORRENTLEECH"
	TITLEROWS=$( less "$TMPFILETORRENTLEECH" | grep '<title>' | grep -n -i -E "$SEARCHPARAMETERS" | awk -F':' '{print $1}' )
	for TITLEROW in ${TITLEROWS[@]}
	do
			TITLE=$( less "$TMPFILETORRENTLEECH" | grep '<title>' | sed -n "$( echo "$TITLEROW" )p" | awk -F'[' '{print $3}' | awk -F']' '{print $1}' )
			LINK=$( less "$TMPFILETORRENTLEECH" | grep '<link>' | sed -n "$( echo "$TITLEROW" )p" | awk -F'[' '{print $3}' | awk -F']' '{print $1}' )
			echo FOUND $TITLE
			echo "TORRENTTITLE: $TITLE" >> $TMPFILE
			echo "TORRENTLINK: $LINK" >> $TMPFILE
	done
	rm -f "$TMPFILETORRENTLEECH"
}
function checkPirateBay() {
	echo '***********************'
	echo "Checking piratebay for $( echo $SEARCHPARAMETERS | sed 's/\|/, /g' )"
	echo '***********************'
	TMPFILEPIRATEBAY='/tmp/piratebay'
	PIRATEBAYURL='http://rss.thepiratebay.se/0'
	curl -s "$PIRATEBAYURL" | xmllint --format - | grep -E '<title>|<link>' | grep -v -E 'All categories|https://thepiratebay.se' > "$TMPFILEPIRATEBAY"
	TITLEROWS=$( less "$TMPFILEPIRATEBAY" | grep '<title>' | grep -n -i -E "$SEARCHPARAMETERS" | awk -F':' '{print $1}' )
	for TITLEROW in ${TITLEROWS[@]}
	do
			TITLE=$( less "$TMPFILEPIRATEBAY" | grep '<title>' | sed -n "$( echo "$TITLEROW" )p" | awk -F'[' '{print $3}' | awk -F']' '{print $1}' )
			LINK=$( less "$TMPFILEPIRATEBAY" | grep '<link>' | sed -n "$( echo "$TITLEROW" )p" | awk -F'<link>' '{print $2}' | awk -F'</link>' '{print $1}' )
			echo FOUND $TITLE
			echo "TORRENTTITLE: $TITLE" >> $TMPFILE
			echo "TORRENTLINK: $LINK" >> $TMPFILE
	done
	rm -f "$TMPFILEPIRATEBAY"
}
function checkKickass() {
	echo '***********************'
	echo "Checking KickassTorrents for $( echo $SEARCHPARAMETERS | sed 's/\|/, /g' )"
	echo '***********************'
	TMPFILEKICKASS='/tmp/kickass'
	KICKASSANIME='http://kickass.to/anime/?rss=1'
	KICKASSMOVIE='http://kickass.to/movies/?rss=1'
	KICKASSTV='http://kickass.to/tv/?rss=1'
	curl -s "$KICKASSANIME" | xmllint --format - | grep -E '<title>|<torrent:magnetURI>' | grep -v 'RSS feed' >  "$TMPFILEKICKASS"
	curl -s "$KICKASSMOVIE" | xmllint --format - | grep -E '<title>|<torrent:magnetURI>' | grep -v 'RSS feed' >> "$TMPFILEKICKASS"
	curl -s "$KICKASSTV"    | xmllint --format - | grep -E '<title>|<torrent:magnetURI>' | grep -v 'RSS feed' >> "$TMPFILEKICKASS"
	TITLEROWS=$( less "$TMPFILEKICKASS" | grep '<title>' | grep -n -i -E "$SEARCHPARAMETERS" | awk -F':' '{print $1}' )
	for TITLEROW in ${TITLEROWS[@]}
	do
			TITLE=$( less "$TMPFILEKICKASS" | grep '<title>' | sed -n "$( echo "$TITLEROW" )p" | awk -F'<title>' '{print $2}' | awk -F'</title>' '{print $1}' )
			LINK=$( less "$TMPFILEKICKASS" | grep '<torrent:magnetURI>' | sed -n "$( echo "$TITLEROW" )p" | awk -F'[' '{print $3}' | awk -F']' '{print $1}' )
			echo FOUND $TITLE
			echo "TORRENTTITLE: $TITLE" >> $TMPFILE
			echo "TORRENTLINK: $LINK" >> $TMPFILE
	done
	rm -f "$TMPFILEKICKASS"
}
function chooseTorrent() {
	if [[ ! $( less $TMPFILE | wc -l ) -eq 1 ]]; then
		echo "Press corresponding number to download torrent: "
		ROWS=$( less $TMPFILE | grep 'TORRENTTITLE: ' | wc -l )
		for ((i = 1; i <= $ROWS; i++))
		do
			TITLE=$( less $TMPFILE | grep 'TORRENTTITLE: ' | sed -n "$( echo $i )p" | awk -F'TORRENTTITLE: ' '{print $2}' )
			echo "$i: $TITLE "
		done
		read INPUT
		if [[ ! -z $INPUT ]]; then
			TORRENT=$( less $TMPFILE | grep 'TORRENTLINK: ' | sed -n "$(( $INPUT ))p" | awk -F'TORRENTLINK: ' '{print $2}' )
			LYNX='download.php'
			#Check for $LYNX in $TORRENT; if contains then download with lynx
			if [[ "${TORRENT#*$LYNX}" != "$TORRENT" ]]; then
				lynx -cfg=~/lynx.cfg "$TORRENT" -dump > /tmp/torrent
				open -a uTorrent '/tmp/torrent'
				rm -f /tmp/torrent
			else
				open -a uTorrent "$TORRENT"
			fi
		fi
	fi
	rm -f $TMPFILE
}
function checkTorrents() {
	TMPFILE='/tmp/torrentResults'
	echo > $TMPFILE
	SEARCHPARAMETERS='rick and morty|archer|cosmos'
	if [[ ! -z "$1" ]]; then
		SEARCHPARAMETERS="$1"
	fi
	checkTorrentLeech
	checkTorrentDay
	checkPirateBay
	checkKickass
	chooseTorrent
}
function helper(){
	echo "Usage:"
	echo "	enter searchparameters to search for with | characters"
	echo "	to indicate multiple search parameters"	
	echo "Options are:"
	echo "	--repeat	repeat function in 30 second intervals"
	echo "	--help		print this usage message"
}
function start() {
	ARGUMENTS="$@"
	REPEATER='--repeat'
	HELPER='--help'
	case $ARGUMENTS in
		$( echo "*$HELPER*" ))
			helper;
			exit;
			;;
		$( echo "*$REPEATER*" ))
			ARGUMENTWITHOUTCMD=$( echo $ARGUMENTS | sed 's/--repeat//g' )
			echo $ARGUMENTWITHOUTCMD
			checkTorrents "$ARGUMENTWITHOUTCMD";
			sleep 30;
			start $ARGUMENTS
			;;
		*)
			checkTorrents "$ARGUMENTS";
			;;
	esac
}
start "$@"