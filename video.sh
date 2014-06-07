function getSeason() {
	SEASON="$1"
}
function getTitle() {
	TITLE="$( echo "$1" )"
}
function getVideos() {
	DIR="/Users/shaman_king_2000/Downloads/Serier/Serier"
	VIDEOEFFIX='.avi|.mkv|.ogm|.mp4'
	TMPFILE='/tmp/videos'
	IFS=$'\n'
	find $DIR -type f | grep -i -E "$VIDEOEFFIX" > "$TMPFILE"
	for VIDEO in $( less $TMPFILE )
	do
		COUNT=$(( $( echo $VIDEO | grep -o '/' | wc -l ) + 1 ))
		FORMATTED=$( echo $VIDEO | awk -v COUNTER=$COUNT -F'/' '{print $COUNTER }' )
		echo TITLE: $FORMATTED
	done
}
function getImdbId() {
	PARAM="$( echo $1 | sed 's/ /\+/g' )"
	URL="http://www.imdb.com/find?q=$PARAM&s=all"
	IMDBID="$( lynx -cfg=~/lynx.cfg "$URL" -source | xmllint --html --format - 2>/dev/null | grep 'fn_al_tt_1"' | awk -F'"result_text"' '{print $2}' | awk -F'"' '{print $2}' | awk -F'/title/' '{print $2}' | awk -F'/?' '{print $1}' )"
	echo IMDBID: $IMDBID
}
function getSerieByImdb() {
	PARAM="$1"
	URL="http://www.thetvdb.com/api/GetSeriesByRemoteID.php?imdbid=$PARAM"
	curl -s "$URL" | xmllint --format - 
}
function getSerieId() {
	PARAM="$( echo $1 | sed 's/ /\+/g' )"
	URL="http://thetvdb.com/api/GetSeries.php?seriesname=$PARAM"
	ID=$( curl -s "$URL" | xmllint --format - | grep '<id>' | awk -F'<id>' '{print $2}' | awk -F'</id>' '{print $1}' )
	echo INFO: $ID
}
getImdbId "$1"
#getVideos