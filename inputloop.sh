if [[ -z "${WORKSPACE}" ]]; then
	echo "Where is your workspace directory? (Don't use ~ characters)"
	read WORKSPACE
fi
OUT_OF_DATE='local out of date'
checkGits() {
	echo "Checking git repositories"
	for gitrepo in $( find $WORKSPACE -name "*.git" | grep -v "tools")
	do
		for outOfDate in $( git --git-dir=$gitrepo remote show origin 2>/dev/null | grep "$OUT_OF_DATE" | awk '{ print $1 }' )
		do
			[ -z "$outOfDate" ] || echo $outOfDate "in" $gitrepo "is out of date"
		done
	done
}
updateGits() {
	echo "Checking git repositories, and updating"
	for gitrepos in $( find "${WORKSPACE}" -name "*.git" | grep -v "tools" )
	do
		echo checking $gitrepos
		for outOfDate in $( git --git-dir="$gitrepos" remote show origin 2>/dev/null | grep "$OUT_OF_DATE" | awk '{ print $1 }' )
		do
			if [[ $outOfDate ]]; then
				currentBranch=$( git --git-dir=$gitrepos status | grep 'On branch' | awk '{ print $4 }' )
				workTree=$( echo $gitrepos | sed -E 's/(.git)+$//' )
				[ "$outOfDate" != "$currentBranch" ] && git --git-dir=$gitrepos --work-tree=$workTree checkout $outOfDate
				echo pulling $outOfDate in $gitrepos
				git --git-dir=$gitrepos --work-tree=$workTree pull
				pomRepo=$( echo $gitrepos | sed -e 's,.git,pom.xml,g' )
				if [[ $( mvn -f $pomRepo clean install 2>/dev/null | grep 'BUILD FAILURE' ) ]]; then
					echo maven failed
				else
					checkServerForArtifact $( find "${WORKSPACE}" $( echo $gitrepos | sed 's/.git//g' ) -type f | grep -E '.ear$|.war$' )
				fi
				[ "$outOfDate" != "$currentBranch" ] && git --git-dir=$gitrepos --work-tree=$workTree checkout $currentBranch

			fi
		done
	done
}

inputloop() {
	echo "-----------------------------------------"
	echo "What would you like to do?: "
	echo "1: Check which gitrepos needs updating"
	echo "2: Update, build and deploy all outdated gitrepos"
	echo "3: Refresh artifacts deployed on running server"

	read INPUT
	if [[ -z "$INPUT" ]]; then
		echo -en "exiting"
	else
		case $INPUT in
		1) checkGits
		;;
		2) updateGits
		;;
		3) refreshServerArtifacts
		;;
		esac
		inputloop
	fi
}
function refreshServerArtifacts() {
	local STP=$( getSTPAPPInstance )
	local IFS=$'\n'
	local DEPLOYED_ARTIFACTS=$( find "$STP/deployments" -type f 2>/dev/null | grep -E '.ear$|.war$' )
	for DEPLOYED_ARTIFACT in $DEPLOYED_ARTIFACTS
	do
		deployToServer "$( echo $DEPLOYED_ARTIFACT | awk -F'/' '{print $5}' )"
	done
}
function deployToServer() {
	local STP="$( getSTPAPPInstance )"
	local ARTIFACT="$1"
	if [[ "$ARTIFACT" =~ ".ear" || "$ARTIFACT" =~ ".war" ]]; then
		local FOUND_ARTIFACTS=$( find "${WORKSPACE}" -type f -name "$ARTIFACT" 2>/dev/null )
	else
		local FOUND_ARTIFACTS=$( find "${WORKSPACE}" -type f -name "$ARTIFACT*.war" -o -name "$ARTIFACT*.ear" 2>/dev/null )
	fi

	for FOUND_ARTIFACT in $FOUND_ARTIFACTS
	do
		echo Deploying artifact "$FOUND_ARTIFACT" to "$STP/deployments"
		cp "$FOUND_ARTIFACT" "$STP/deployments"
	done

	if [[ -z "$FOUND_ARTIFACTS" ]]; then
		echo Could not find artifact "$ARTIFACT"	
	fi
}
function getSTPAPPInstance() {
	echo $( ps -ef | grep 'jboss.server.base.dir' | grep -v grep | awk -F'jboss.server.base.dir=' '{print $2}' | grep -v 'print' | awk '{print $1}' )
}
function checkServerForArtifact() {
	ARTIFACT="$1"
	STP="$( getSTPAPPInstance )"
	IFS=$'\n'
	DEPLOYED_ARTIFACTS=$( find "$STP/deployments" -type f 2>/dev/null | grep -E '.ear$|.war$' | awk -F'/' '{print $NF}' )
	ART=$( echo $ARTIFACT | awk -F'/' '{print $NF}' )
	if [[ -n $( echo $DEPLOYED_ARTIFACTS | grep $ART ) ]]; then
		echo Deploying "$ARTIFACT" to "$STP/deployments"
		cp "$ARTIFACT" "$STP/deployments"
	fi
}
inputloop
