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
		git --git-dir="$GIT_REPO" --work-tree="$WORK_TREE" $COMMAND 2>/dev/null | grep "$3"
	else
		git --git-dir="$GIT_REPO" --work-tree="$WORK_TREE" $COMMAND 2>/dev/null
	fi
}
function checkGits() {
	echo "Checking git repositories"
	for GITREPO in $( find $WORKSPACE -name "*.git" )
	do
		#Check branches for outdated repos
		for BRANCH_OUT_OF_DATE in $( gitCommand "$GITREPO" "remote show origin" "$OUT_OF_DATE" | awk '{print $1}' )
		do
			#If branch is outdated, echo result
			[ -n "$BRANCH_OUT_OF_DATE" ] && echo "$BRANCH_OUT_OF_DATE in $GITREPO is out of date"
		done
	done
}
function updateGits() {
	echo "Checking git repositories, and updating"
	for GITREPO in $( find "${WORKSPACE}" -name "*.git" )
	do
		echo checking $GITREPO
		#Get outdated branches of $GITREPO
		for BRANCH_OUT_OF_DATE in $( gitCommand "$GITREPO" "remote show origin" "$OUT_OF_DATE" | awk '{print $1}' )
		do
			#Get current branch
			local CURRENT_BRANCH=$( gitCommand "$GITREPO" "status" "$ON_BRANCH" | awk '{print $3}' )
			local WORK_TREE=$( echo "$GITREPO" | sed -E 's/(.git)+$//' )
			#If outdated branch != current branch, change branch to outdated
			[ "$BRANCH_OUT_OF_DATE" != "$CURRENT_BRANCH" ] && gitCommand "$GITREPO" "checkout $BRANCH_OUT_OF_DATE"
			echo pulling $BRANCH_OUT_OF_DATE in $GITREPO
			gitCommand "$GITREPO" "pull"
			#Get path to top-level pom.xml
			local POM_REPO=$( echo "$GITREPO" | sed -e 's/\.git/pom.xml/g' )
			#Compile project and check for failure
			if [[ -n $( mvn -f "$POM_REPO" clean install 2>/dev/null | grep 'BUILD FAILURE' ) ]]; then
				echo maven failed
			else
				#Check if server is running, and if artifact is deployed, then deploy artifact to server
				checkServerForArtifactsAndDeploy $( find "$( echo $GITREPO | sed 's/\.git//g' )" -type f | grep -E '.ear$|.war$' )
			fi
			#Change back to original branch if outdated branch != original branch
			[ "$BRANCH_OUT_OF_DATE" != "$CURRENT_BRANCH" ] && gitCommand "$GITREPO" "checkout $CURRENT_BRANCH"
		done
	done
}

function inputloop() {
	echo "-----------------------------------------"
	echo "What would you like to do?: enter empty to exit"
	echo "1: Check which gitrepos needs updating"
	echo "2: Update, build and deploy all outdated gitrepos"
	echo "3: Refresh artifacts deployed on running server"
	echo "4: Change environment in standalone.xml"
	echo "5: Deploy single artifact to running server"
	echo "6: Check for uncommitted changes"
	echo "7: Start server"

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
		5)
			echo "Enter name of artifact that you want to deploy e.g vara-ear"
			read ARTIFACT
			deployToJboss "$ARTIFACT"
		;;
		6) checkForUncommittedGitRepos
		;;
		7) startServer
		;;
		esac
		inputloop
	fi
}
function startServer(){
	echo "-----------------------------------------"
	echo "Which server would you like to start?"
	echo "1: JBOSS"
	echo "2: TOMCAT"
	echo "3: GLASSFISH"
	read INPUT
	if [[ -n "$INPUT" ]]; then
		case "$INPUT" in
			1)
				echo "Starting JBOSS"
			;;
			2)
				echo "Starting TOMCAT"
			;;
			3)
				echo "Starting GLASSFISH"
			;;
		esac
	fi
}
function refreshServerArtifacts() {
	local STP=$( getSTPAPPDIR )
	local IFS=$'\n'
	#Check running server's deployed artifacts
	local DEPLOYED_ARTIFACTS=$( find "$STP/deployments" -type f 2>/dev/null | grep -E '.ear$|.war$' )
	for DEPLOYED_ARTIFACT in $DEPLOYED_ARTIFACTS
	do
		#get artifact-name from path
		deployToJboss "$( echo $DEPLOYED_ARTIFACT | awk -F'/' '{print $NF}' )"
	done
}
function deployToJboss() {
	#Get running server directory
	local STP="$( getSTPAPPDIR )"
	local ARTIFACT="$1"
	#Check if $ARTIFACT is full artifact-name or short-version e.g. vara-ear
	if [[ "$ARTIFACT" =~ ".ear" || "$ARTIFACT" =~ ".war" ]]; then
		local FOUND_ARTIFACTS=$( find "${WORKSPACE}" -type f -name "$ARTIFACT" 2>/dev/null )
	else
		local FOUND_ARTIFACTS=$( find "${WORKSPACE}" -type f -name "$ARTIFACT*.war" -o -name "$ARTIFACT*.ear" 2>/dev/null )
	fi

	for FOUND_ARTIFACT in $FOUND_ARTIFACTS
	do
		deploy "$FOUND_ARTIFACT" "$STP/deployments"
	done

	if [[ -z "$FOUND_ARTIFACTS" ]]; then
		echo Could not find artifact "$ARTIFACT"	
	fi
}
function getSTPAPPDIR() {
	#Get running server info, and echo path-dir e.g. /opt/stpapp
	echo $( ps -ef | grep 'jboss.server.base.dir' | grep -v grep | awk -F'jboss.server.base.dir=' '{print $2}' | grep -v 'print' | awk '{print $1}' )
}
function getGLASSFISHDIR(){
	echo $( ps -ef | grep 'glassfish' | grep 'launchctl' | awk -F'instanceRoot=' '{print $2}' | awk '{print $1}' )
}
function getTOMCATDIR(){
	echo $( ps -ef | grep 'catalina' | awk -F'-Dcatalina.home=' '{print $2}' | awk '{print $1}' )
}
function deployToTomcat(){
	local ARTIFACT="$1"
	local TOMCAT="$( getTOMCATDIR )/webapps"
	deploy "$ARTIFACT" "$TOMCAT"
}
function deployToGlassfish(){
	local ARTIFACT="$1"
	local GLASSFISH="$( getGLASSFISHDIR )"
	if [[ -n "$ARTIFACT" && -n "$GLASSFISH" ]]; then
		echo "Deploying $ARTIFACT to $GLASSFISH"
		asadmin deploy --force "$ARTIFACT"
	fi
}
function checkForUncommittedGitRepos(){
	for GITREPO in $( find ${WORKSPACE} -type d -name ".git" 2>/dev/null )
	do
		if [[ -n "$( gitCommand "$GITREPO" "status" "Changes not staged for commit" )" ]]; then
			echo "Gitrepo $GITREPO has uncommitted changes"
		fi
	done
}
function deploy(){
	local ARTIFACT="$1"
	local SERVER_DEPLOY_DIR="$2"
	if [[ -n "$ARTIFACT" && -n "$SERVER_DEPLOY_DIR" ]]; then
		if [[ -n "$( find $SERVER_DEPLOY_DIR -type d | grep "$SERVER_DEPLOY_DIR\$" )" ]]; then
			if [[ -n "$( find $ARTIFACT -type f )" ]]; then
				echo "Deploying $ARTIFACT to $SERVER_DEPLOY_DIR"
				cp "$ARTIFACT" "$SERVER_DEPLOY_DIR"
			fi
		fi
	fi
}
function checkWhichRunningServerAndDeploy(){
	local ARTIFACT="$1"
	local GLASSFISH_SERVER="$( getGLASSFISHDIR )"
	local TOMCAT_SERVER="$( getTOMCATDIR )"
	local JBOSS_SERVER="$( getSTPAPPDIR )"

	[[ -n "$JBOSS_SERVER" ]] && deployToJboss "$ARTIFACT"
	[[ -n "$GLASSFISH_SERVER" ]] && deployToGlassfish "$ARTIFACT"
	[[ -n "$TOMCAT_SERVER" ]] && deployToTomcat "$ARTIFACT"

	if [[ -z "$JBOSS_SERVER" && "$GLASSFISH_SERVER" && -z "$TOMCAT_SERVER" ]]; then
		echo "No running servers."
	fi
}
function checkServerForArtifactsAndDeploy() {
	local ARTIFACT="$1"
	local STP="$( getSTPAPPDIR )"
	local IFS=$'\n'
	#Get deployed artifact-names from running server
	local DEPLOYED_ARTIFACTS=$( find "$STP/deployments" -type f 2>/dev/null | grep -E '.ear$|.war$' | awk -F'/' '{print $NF}' )
	local ART=$( echo $ARTIFACT | awk -F'/' '{print $NF}' )
	if [[ -n $( echo $DEPLOYED_ARTIFACTS | grep $ART ) ]]; then
		deploy "$ARTIFACT" "$STP/deployments"
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