if [[ -z "${WORKSPACE}" ]]; then
	echo "Where is your workspace directory? (Don't use ~ characters)"
	echo "Provide WORKSPACE environment variable to skip this step"
	read WORKSPACE
fi

#FÖR GIT PÅ ENGELSKA
OUT_OF_DATE='local out of date'
ON_BRANCH='On branch'
#FÖR GIT PÅ SVENSKA
#OUT_OF_DATE=''
#ON_BRANCH=''

function gitCommand() {
	local GIT_REPO="$1"
	local WORK_TREE="$( echo $GITREPO | sed 's/\.git//g' )"
	local COMMAND="$2"
	if [[ -n "$3" ]]; then
		echo $( git --git-dir="$GIT_REPO" --work-tree="$WORK_TREE" $COMMAND 2>/dev/null | grep "$3" )
	else
		echo $( git --git-dir="$GIT_REPO" --work-tree="$WORK_TREE" $COMMAND 2>/dev/null )
	fi
}
function checkGits() {
	echo "Checking git repositories"
	for GITREPO in $( find $WORKSPACE -name "*.git" )
	do
		for BRANCH_OUT_OF_DATE in $( gitCommand "$GITREPO" "remote show origin" "$OUT_OF_DATE" | awk '{print $1}' )
		do
			[ -n "$BRANCH_OUT_OF_DATE" ] && echo "$BRANCH_OUT_OF_DATE in $GITREPO is out of date"
		done
	done
}
function updateGits() {
	echo "Checking git repositories, and updating"
	for GITREPO in $( find "${WORKSPACE}" -name "*.git" )
	do
		echo checking $GITREPO
		for BRANCH_OUT_OF_DATE in $( gitCommand "$GITREPO" "remote show origin" "$OUT_OF_DATE" | awk '{print $1}' )
		#for BRANCH_OUT_OF_DATE in $( git --git-dir="$GITREPO" remote show origin 2>/dev/null | grep "$OUT_OF_DATE" | awk '{ print $1 }' )
		do
			local CURRENT_BRANCH=$( gitCommand "$GITREPO" "status" "$ON_BRANCH" | awk '{print $4}' )
			#local CURRENT_BRANCH=$( git --git-dir=$GITREPO status | grep $ON_BRANCH | awk '{ print $4 }' )
			local WORK_TREE=$( echo "$GITREPO" | sed -E 's/(.git)+$//' )
			[ "$BRANCH_OUT_OF_DATE" != "$CURRENT_BRANCH" ] && gitCommand "$GITREPO" "checkout $BRANCH_OUT_OF_DATE"
			#[ "$BRANCH_OUT_OF_DATE" != "$CURRENT_BRANCH" ] && git --git-dir=$GITREPO --work-tree=$WORK_TREE checkout $BRANCH_OUT_OF_DATE
			echo pulling $BRANCH_OUT_OF_DATE in $GITREPO
			gitCommand "$GITREPO" "pull"
			#git --git-dir=$GITREPO --work-tree=$WORK_TREE pull
			local POM_REPO=$( echo "$GITREPO" | sed -e 's/\.git/pom.xml/g' )
			if [[ -n $( mvn -f "$POM_REPO" clean install 2>/dev/null | grep 'BUILD FAILURE' ) ]]; then
				echo maven failed
			else
				checkServerForArtifactsAndDeploy $( find "$( echo $GITREPO | sed 's/\.git//g' )" -type f | grep -E '.ear$|.war$' )
			fi
			[ "$BRANCH_OUT_OF_DATE" != "$CURRENT_BRANCH" ] && gitCommand "$GITREPO" "checkout $CURRENT_BRANCH"
			#[ "$BRANCH_OUT_OF_DATE" != "$CURRENT_BRANCH" ] && git --git-dir="$GITREPO" --work-tree="$WORK_TREE" checkout "$CURRENT_BRANCH"
		done
	done
}

function inputloop() {
	echo "-----------------------------------------"
	echo "What would you like to do?: "
	echo "1: Check which gitrepos needs updating"
	echo "2: Update, build and deploy all outdated gitrepos"
	echo "3: Refresh artifacts deployed on running server"
	echo "4: Change environment in standalone.xml"

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
		4)
			echo "Which environment do you want to change to? e.g. INT8 or UTV1"
			read ENV
			echo "Write path to standalone.xml e.g. /opt/stpapp/configuration/standalone.xml"
			read STANDALONE
			changeStandaloneToEnv "$STANDALONE" "$ENV"
		;;
		esac
		inputloop
	fi
}
function refreshServerArtifacts() {
	local STP=$( getSTPAPPDIR )
	local IFS=$'\n'
	local DEPLOYED_ARTIFACTS=$( find "$STP/deployments" -type f 2>/dev/null | grep -E '.ear$|.war$' )
	for DEPLOYED_ARTIFACT in $DEPLOYED_ARTIFACTS
	do
		deployToServer "$( echo $DEPLOYED_ARTIFACT | awk -F'/' '{print $5}' )"
	done
}
function deployToServer() {
	local STP="$( getSTPAPPDIR )"
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
function getSTPAPPDIR() {
	echo $( ps -ef | grep 'jboss.server.base.dir' | grep -v grep | awk -F'jboss.server.base.dir=' '{print $2}' | grep -v 'print' | awk '{print $1}' )
}
function checkServerForArtifactsAndDeploy() {
	local ARTIFACT="$1"
	local STP="$( getSTPAPPDIR )"
	local IFS=$'\n'
	local DEPLOYED_ARTIFACTS=$( find "$STP/deployments" -type f 2>/dev/null | grep -E '.ear$|.war$' | awk -F'/' '{print $NF}' )
	local ART=$( echo $ARTIFACT | awk -F'/' '{print $NF}' )
	if [[ -n $( echo $DEPLOYED_ARTIFACTS | grep $ART ) ]]; then
		echo Deploying "$ARTIFACT" to "$STP/deployments"
		cp "$ARTIFACT" "$STP/deployments"
	fi
}

function changeStandaloneToEnv(){
	local STANDALONE="$1"	
	local ENV="$2"
	#Check that $STANDALONE && $ENV is not empty and $STANDALONE is existing file
	if [[ -n "$STANDALONE" && -n "$ENV" && -n "$( find "$STANDALONE" -type f 2>/dev/null )" ]]; then
		case "$ENV" in
			"UTV1" | "UTV2" | "UTV3" | "UTV4" | "UTV5")
				local HOSTENV='usb2ud03.systest.receptpartner.se'
				;;
			"UTV6" | "UTV7" | "UTV8" | "UTV9" | "UTV10")
				local HOSTENV='usb2ud04.systest.receptpartner.se'
				;;
			"INT1" | "INT2" | "INT3" | "INT4" | "INT5" | "INT6" | "INT7" | "INT8" | "INT9" | "INT10" | "INT11" | "INT12")
				local HOSTENV='td01-scan.systest.receptpartner.se'
				;;
			"XE")
				local HOSTENV='localhost'
				;;
			*)
				local HOSTENV=''
				;;
		esac
		#change SERVICE_NAME = ? to $ENV and HOST = ? to $HOSTENV if $HOSTENV is not empty
		if [[ -n "$HOSTENV" ]]; then
			sed -i -e "s/SERVICE_NAME = \w\{2,4\}/SERVICE_NAME = $ENV/g" -e "s/HOST = [a-zA-Z0-9.-]\{4,200\}/HOST = $HOSTENV/g" "$STANDALONE"
			echo "Changed host to $HOSTENV and servicename to $ENV in $STANDALONE"
		else
			echo "Environment variable is not valid"
		fi
	else
		echo "Either path or environment variable is empty or path is not valid"
	fi
}

inputloop
