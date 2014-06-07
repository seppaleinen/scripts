function getViewCounts() {
	URL="$1"
	VIMEO=$( echo "$URL" | grep -i 'vimeo' )
	if [[ -z "$VIMEO" ]]; then
		VIEWCOUNTROW=$(( $( lynx $CFG $URL -source | grep -n '"watch7-views-info"' | awk -F':' '{print $1}' ) + 1 ))
		VIEWCOUNT=$( lynx $CFG $URL -source | sed -n "$VIEWCOUNTROW p" | sed 's/ //g' )
		if [[ ! -z $( echo $VIEWCOUNT | grep 'hovercard' ) ]]; then
			VIEWCOUNTROW=$(( $VIEWCOUNTROW + 1 ))
			VIEWCOUNT=$( lynx $CFG $URL -source | sed -n "$VIEWCOUNTROW p" | sed 's/ //g' )
		fi
		echo $VIEWCOUNT
	fi
}
function getURLandTITLE() {
	URL="$1"
	VIDEOS=$( lynx "$CFG" "$URL" -source | xmllint --html --format - 2>/dev/null | grep '<a class="title' | grep -v 'a_reminder_about_personal_information' );
	IFS=$'\n'
	for VIDEO in $VIDEOS
	do
		TITLE=$( echo $VIDEO | awk -F'</a>' '{print $1}' | awk -F'>' '{print $3}' )
		LINK=$( echo $VIDEO | awk -F'href="' '{print $2}' | awk -F'"' '{print $1}' )
		GREP=$( less $TMPFILE | grep $LINK )
		if [[ -z $GREP ]]; then
			VIEWS=$( getViewCounts "$LINK" )
			echo TITLE $TITLE
			echo LINK $LINK
			echo VIEWS $VIEWS
			echo $LINK >> $TMPFILE
		else
			echo DUPLICATE
			echo $TITLE
			echo DUPLICATE
		fi
		echo '#######################################'
	done
}
function getNextPage() {
	URL="$1"
	LYNX=$( lynx -cfg=~/lynx.cfg "$URL" -source | xmllint --html --format - 2>/dev/null | grep 'rel="nofollow next"' )
	if [[ -z $( echo $LYNX | grep 'class="separator"' ) ]]; then
		NEXTURL=$( echo $LYNX | awk -F'" rel="nofollow next"' '{print $1}' | awk -F'<a href="' '{print $2}' )
	else
		NEXTURL=$( echo $LYNX | awk -F'" rel="nofollow next"' '{print $1}' | awk -F'<a href="' '{print $3}' )
	fi
	echo "$NEXTURL"
}
function main() {
	URL="$1"
	getURLandTITLE "$URL"
	NEXTPAGE="$( getNextPage "$URL" )"
	if [[ ! -z "$NEXTPAGE" ]]; then
		echo PAGE: "$( echo $NEXTPAGE | awk -F'count=' '{print $2}' | awk -F'&amp;' '{print $1}' )"
		main "$NEXTPAGE"
	fi
}
CFG='-cfg=~/lynx.cfg'
TMPFILE='/tmp/tmpreddit'
echo > "$TMPFILE"
main "www.reddit.com/r/videos/"