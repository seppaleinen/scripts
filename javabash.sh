function JAVABASH() {
	IFS=$'\n'
	SEARCHRESULTS=$( find ~/Downloads -type f -name "*.avi" -o -name "*.mpg" -o -name "*.mkv" -o -name "*.mp4" -o -name "*.mpeg" )
	cd ~/Downloads
	java Java $SEARCHRESULTS
	cd .
}
JAVABASH "$1"