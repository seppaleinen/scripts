if [[ -z "${WORKSPACE}" ]]; then
  echo "Where is your workspace directory? (Don't use ~ characters)"
  echo "Provide WORKSPACE environment variable to skip this step"
  read WORKSPACE
fi

#FÖR GIT PÅ ENGELSKA
readonly OUT_OF_DATE='local out of date'
readonly ON_BRANCH='On branch'

#######################################
# executes git command
# Globals:
# 	None
# Arguments:
#   GIT_REPO
#	COMMAND
# Returns:
#   echo of git result
#######################################
function git_command() {
  local GIT_REPO="$1"
  local WORK_TREE="$( echo $GITREPO | sed 's/\.git//g' )"
  local COMMAND="$2"
  if [[ -n "$3" ]]; then
    git --git-dir="$GIT_REPO" --work-tree="$WORK_TREE" $COMMAND 2>/dev/null | grep "$3"
  else
    git --git-dir="$GIT_REPO" --work-tree="$WORK_TREE" $COMMAND 2>/dev/null
  fi
}
#######################################
# Check which git repos are outdated
# Globals:
#   WORKSPACE
# Arguments:
#   None
# Returns:
#   None
#######################################
function check_gits() {
  echo "Checking git repositories"
  for GITREPO in $( find "${WORKSPACE}" -name "*.git" )
  do
    #Check branches for outdated repos
    for BRANCH_OUT_OF_DATE in $( git_command "$GITREPO" "remote show origin" "$OUT_OF_DATE" | awk '{print $1}' )
	do
	  #If branch is outdated, echo result
	  [[ -n "$BRANCH_OUT_OF_DATE" ]] && echo "$BRANCH_OUT_OF_DATE in $GITREPO is out of date"
	done
  done
}
#######################################
# Check which git repos are outdated, build and deploy if successful
# Globals:
#   WORKSPACE
# Arguments:
#   None
# Returns:
#   None
#######################################
function update_gits() {
  echo "Checking git repositories, and updating"
  for GITREPO in $( find "${WORKSPACE}" -name "*.git" )
  do
    echo checking $GITREPO
	#Get outdated branches of $GITREPO
	for BRANCH_OUT_OF_DATE in $( git_command "$GITREPO" "remote show origin" "$OUT_OF_DATE" | awk '{print $1}' )
	do
	  #Get current branch
	  local CURRENT_BRANCH=$( git_command "$GITREPO" "status" "$ON_BRANCH" | awk '{print $3}' )
	  local WORK_TREE=$( echo "$GITREPO" | sed -E 's/(.git)+$//' )
	  #If outdated branch != current branch, change branch to outdated
      [[ "$BRANCH_OUT_OF_DATE" != "$CURRENT_BRANCH" ]] && git_command "$GITREPO" "checkout $BRANCH_OUT_OF_DATE"
	  echo pulling $BRANCH_OUT_OF_DATE in $GITREPO
	  git_command "$GITREPO" "pull"
	  #Get path to top-level pom.xml
	  local POM_REPO=$( echo "$GITREPO" | sed -e 's/\.git/pom.xml/g' )
      #Compile project and check for failure
	  if [[ -n $( mvn -f "$POM_REPO" clean install 2>/dev/null | grep 'BUILD FAILURE' ) ]]; then
	    echo maven failed
	  else
	    #Check if server is running, and if artifact is deployed, then deploy artifact to server
		check_server_for_artifacts_and_deploy $( find "$( echo $GITREPO | \
			sed 's/\.git//g' )" -type f | grep -E '.ear$|.war$' )
	  fi
	  #Change back to original branch if outdated branch != original branch
	  [[ "$BRANCH_OUT_OF_DATE" != "$CURRENT_BRANCH" ]] && git_command "$GITREPO" "checkout $CURRENT_BRANCH"
	done
  done
}
function check_for_uncommitted_git_repos(){
  for GITREPO in $( find ${WORKSPACE} -type d -name ".git" 2>/dev/null )
  do
    if [[ -n "$( git_command "$GITREPO" "status" "Changes not staged for commit" )" ]]; then
      echo "Gitrepo $GITREPO has uncommitted changes"
	fi
  done
}
#######################################
# Present choice of which function to call
# Globals:
#	None
# Arguments:
#   None
# Returns:
#   None
#######################################
function inputloop() {
  echo "-----------------------------------------"
  echo "What would you like to do?: enter empty to exit"
  echo "1: Check which gitrepos needs updating"
  echo "2: Update, build and deploy all outdated gitrepos"
  echo "3: Refresh artifacts deployed on running server"
  echo "4: Change environment in standalone.xml"
  echo "5: Set soaptest parameters to local"
  echo "6: Deploy single artifact to running server"
  echo "7: rebuild database testdata"
  echo "8: Check for uncommitted changes"
  echo "9: Change branch on stp"

  read INPUT
  if [[ -z "$INPUT" ]]; then
    echo -en "exiting"
  else
    case $INPUT in
	  1) check_gits
	  ;;
	  2) update_gits
	  ;;
	  3) refresh_server_artifacts
	  ;;
	  4)
	    echo "Which environment do you want to change to? e.g. INT8 or UTV1"
		  read ENV
		  echo "Write path to stpapp e.g. /opt/stpappOr"
		  read STANDALONE
		  change_standalone_to_env "$STANDALONE" "$ENV"
	  ;;
    5) setSoapEnv
    ;;
	  6)
	    echo "Enter name of artifact that you want to deploy e.g vara-ear"
		  read ARTIFACT
		  deploy_to_jboss "$ARTIFACT"
	  ;;
    7) rebuildDatabase
    ;;
	  8) check_for_uncommitted_git_repos
	  ;;
    9) changeBranchOnAllSTP
    ;;
	esac
	inputloop
  fi
}
#######################################
# Check which artifacts are deployed on server, and redeploy
# Globals:
#   ORACLE_SID
# Arguments:
#   None
# Returns:
#   None
#######################################
function refresh_server_artifacts() {
  local STP="$( get_jbossdir )"
  [[ -z "$STP" ]] && echo "JBOSS server not running"
  local IFS=$'\n'
  #Check running server's deployed artifacts
  local DEPLOYED_ARTIFACTS=$( find "$STP/deployments" -type f 2>/dev/null | grep -E '.ear$|.war$' )
  for DEPLOYED_ARTIFACT in $DEPLOYED_ARTIFACTS
  do
    #get artifact-name from path
	deploy_to_jboss "$( echo $DEPLOYED_ARTIFACT | awk -F'/' '{print $NF}' )"
  done
}
#######################################
# Change jboss standalone.xml config to environment value
# Globals:
#   None
# Arguments:
#	ARTIFACT
# Returns:
#   None
#######################################
function check_which_running_server_and_deploy(){
  local ARTIFACT="$1"
  local GLASSFISH_SERVER="$( get_glassfishdir )"
  local TOMCAT_SERVER="$( get_tomcatdir )"
  local JBOSS_SERVER="$( get_jbossdir )"

  [[ -n "$JBOSS_SERVER" ]] && deploy_to_jboss "$ARTIFACT"
  [[ -n "$GLASSFISH_SERVER" ]] && deploy_to_glassfish "$ARTIFACT"
  [[ -n "$TOMCAT_SERVER" ]] && deploy_to_tomcat "$ARTIFACT"

  if [[ -z "$JBOSS_SERVER" && "$GLASSFISH_SERVER" && -z "$TOMCAT_SERVER" ]]; then
	echo "No running servers."
  fi
}
#######################################
# Check running server for deployed artifacts and refresh
# Globals:
#   None
# Arguments:
#   ARTIFACT
# Returns:
#   None
#######################################
function check_server_for_artifacts_and_deploy() {
  local ARTIFACT="$1"
  local STP="$( get_jbossdir )"
  if [[ -n "$STP" ]]; then
  	local IFS=$'\n'
    #Get deployed artifact-names from running server
    local DEPLOYED_ARTIFACTS=$( find "$STP/deployments" -type f 2>/dev/null | grep -E '.ear$|.war$' | awk -F'/' '{print $NF}' )
    local ART=$( echo $ARTIFACT | awk -F'/' '{print $NF}' )
    if [[ -n $( echo $DEPLOYED_ARTIFACTS | grep $ART ) ]]; then
      deploy "$ARTIFACT" "$STP/deployments"
  	fi
  else
  	echo "JBOSS server not running"
  fi
}
function getEnvURL() {
  local ENV="$1"
  case "$ENV" in
    "UTV1" | "UTV2" | "UTV3" | "UTV4" | "UTV5")
    local HOSTENV='usb2ud03.systest.receptpartner.se'
    ;;
    "UTV6" | "UTV7" | "UTV8" | "UTV9" | "UTV10")
    local HOSTENV='usb2ud04.systest.receptpartner.se'
    ;;
    "INT1" | "INT2" | "INT3" | "INT4" | "INT5" | "INT6" | \
    "INT7" | "INT8" | "INT9" | "INT10" | "INT11" | "INT12")
    local HOSTENV='td01-scan.systest.receptpartner.se'
    ;;
    "XE")
    local HOSTENV='localhost'
    ;;
    "CI1" | "CI2" | "CI3" | "CI4" | "CI5" | "CI6")
    local HOSTENV='usb2ud04.systest.receptpartner.se'
    ;;
    *)
      local HOSTENV=''
    ;;
  esac
  echo "$HOSTENV"
}
#######################################
# Change jboss standalone.xml config to environment value
# Globals:
#   None
# Arguments:
#   STANDALONE
#	ENV
# Returns:
#   None
#######################################
function change_standalone_to_env(){
  local PATH_TO_STPAPP="$1"
  local STANDALONE="$PATH_TO_STPAPP/configuration/standalone.xml"	
  local ENV="$2"
  #Check that $STANDALONE && $ENV is not empty and $STANDALONE is existing file
  if [[ -n "$STANDALONE" && -n "$ENV" && -n "$( find "$STANDALONE" -type f 2>/dev/null )" ]]; then
  local HOSTENV=$( getEnvURL "$ENV" )
	#change SERVICE_NAME = ? to $ENV and HOST = ? to $HOSTENV if $HOSTENV is not empty
	if [[ -n "$HOSTENV" ]]; then
	  sed -i -e "s/SERVICE_NAME = \w\{2,4\}/SERVICE_NAME = $ENV/g" \
	    -e "s/HOST = [a-zA-Z0-9.-]\{4,200\}/HOST = $HOSTENV/g" "$STANDALONE"
	  echo "Changed host to $HOSTENV and servicename to $ENV in $STANDALONE"
	else
	  echo "Environment variable is not valid"
	fi
  else
    echo "Either path or environment variable is empty or path is not valid"
  fi
}
function get_jbossdir() {
  #Get running server info, and echo path-dir e.g. /opt/stpapp
  echo "$( ps -ef | \
   grep 'jboss.server.base.dir' | \
   grep -v grep | \
   awk -F'jboss.server.base.dir=' '{print $2}' | \
   grep -v 'print' | \
   awk '{print $1}' )"
}
function get_glassfishdir(){
  echo "$( ps -ef | \
  	grep 'glassfish' | \
  	grep 'launchctl' | \
  	awk -F'instanceRoot=' '{print $2}' | \
  	awk '{print $1}' )"
}
function get_tomcatdir(){
  echo "$( ps -ef | \
  	grep 'catalina' | \
  	awk -F'-Dcatalina.home=' '{print $2}' | \
  	awk '{print $1}' )"
}
function deploy_to_tomcat(){
  local ARTIFACT="$1"
  local TOMCAT="$( get_tomcatdir )/webapps"
  deploy "$ARTIFACT" "$TOMCAT"
}
function deploy_to_glassfish(){
  local ARTIFACT="$1"
  local GLASSFISH="$( get_glassfishdir )"
  if [[ -n "$ARTIFACT" && -n "$GLASSFISH" ]]; then
    echo "Deploying $ARTIFACT to $GLASSFISH"
	asadmin deploy --force "$ARTIFACT"
  fi
}
#######################################
# Deploy artifact to jboss
# Globals:
#   WORKSPACE
# Arguments:
#   ARTIFACT
# Returns:
#   None
#######################################
function deploy_to_jboss() {
  #Get running server directory
  local STP="$( get_jbossdir )"
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
#######################################
# Deploy ARTIFACT to SERVER_DEPLOY_DIR
# Globals:
#   None
# Arguments:
#   ARTIFACT
# SERVER_DEPLOY_DIR
# Returns:
#   None
#######################################
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
function runSoapTests(){
  echo "Which project?"
  read PROJECT
  local PROJECTDIR=$( find "$WORKSPACE" -type d -wholename "*$PROJECT/.git" 2>/dev/null | sed 's/\.git//g' )
  local TEST_FILES=$( find "$PROJECTDIR" -type f -wholename "*$PROJECT-soapui*/resources/regressionstest*" 2>/dev/null | grep '.xml$' )

  local RUNNING_JBOSS_DIR="$( get_jbossdir )"
  local JDBC_CONFIG="$( less "$RUNNING_JBOSS_DIR/configuration/standalone.xml" | grep 'jdbc:' | head -1 )"
  local HOST="$( echo $JDBC_CONFIG | awk -F'HOST = ' '{print $2}' | awk -F')' '{print $1}' )"
  local SERVICE="$( echo $JDBC_CONFIG | awk -F'SERVICE_NAME = ' '{print $2}' | awk -F')' '{print $1}' )"
  local TESTRESULT="$WORKSPACE/tmpsoapresult.txt"
  local SOAPFILE="$WORKSPACE/tmpsoaptest.xml"

  rm -f "$TESTRESULT"
  touch "$TESTRESULT"

  for TEST_FILE in $TEST_FILES
  do
    cp "$TEST_FILE" "$SOAPFILE"

    setSoapTestToEnv_private "$SOAPFILE" "$HOST" "$SERVICE"

    sh $SOAPUI_HOME/bin/testrunner.sh -r "$SOAPFILE" >> "$TESTRESULT"

    rm -f "$SOAPFILE"
  done
}

function setSoapTestToEnv_private() {
  local SOAPFILE="$1"
  local HOST="$2"
  local SERVICE="$3"

  if [[ -n $( less "$SOAPFILE" | xmllint --format - | grep 'jdbc:' ) ]]; then
      #Change jdbc: configurations to that of the servers ex. td01-scan.systest.receptpartner.se/INT8
      sed -i 's_@[a-zA-Z0-9./:-]*</con:value>_@'$HOST/$SERVICE'</con:value>_g' "$SOAPFILE"
      #Change serviceEndpoint to localhost
      sed -i 's_<con:value>http://[a-zA-Z0-9.-]\{12,40\}:[0-9]\{5,5\}</con:value>_<con:value>http://localhost:20080</con:value>_g' "$SOAPFILE"
      #Change USER_LOGGING path to WORKSPACE/tmplog
      sed -i 's?<con:name>USER_LOGGING</con:name><con:value>[a-zA-Z0-9./\_-]*</con:value>?<con:name>USER_LOGGING</con:name><con:value>'$WORKSPACE/tmplog'</con:value>?g' "$SOAPFILE"

      #less "$WORKSPACE/tmpsoaptest.xml" | xmllint --format - | grep 'localhost:20080'
  fi
}

function setSoapEnv() {
  echo "Which project?";
  read PROJECT
  echo "Which environment?"
  read ENV
  local TEST_FILES=$( find "$WORKSPACE" -type f -wholename "*$PROJECT-soapui*/resources/regressionstest*" 2>/dev/null | grep '\.xml$' )
  local URL=$( getEnvURL "$ENV" )

  for TEST_FILE in $TEST_FILES
  do
    setSoapTestToEnv_private "$TEST_FILE" "$URL" "$ENV"
  done
}

function rebuildDatabase_private() {
  local URL="$1"
  local USERNAME_AND_PASSWORD="$2"
  local CONTEXT="$3"

  java -jar -Duser.country=SE "$SOAPUI_HOME/bin/ext/liquibase.jar" \
                      --classpath="$SOAPUI_HOME/bin/ext/ojdbc6.jar" \
                      --url="$URL" \
                      --username="$USERNAME_AND_PASSWORD" \
                      --password="$USERNAME_AND_PASSWORD" \
                      --contexts="$CONTEXT" \
                      --changeLogFile="updateTestdata.xml" \
                      --driver="oracle.jdbc.OracleDriver" update

}

function rebuildDatabase() {
  echo "Which project?"
  read PROJECT
  echo "Which environment?"
  read ENV
  echo "Which user?"
  read USERNAME
  echo "Which context?"
  read CONTEXT

  local URL=$( getEnvURL "$ENV" )
  rebuildDatabase_private "$URL" "$USERNAME" "$CONTEXT"
}

function changeBranchOnAllSTP() {
  echo "Which branch do you want to change to?"
  read BRANCH
  for GIT_REPO in $( find "${WORKSPACE}" -name "*.git" )
  do
    local WORK_TREE="$( echo $GIT_REPO | sed 's/\.git//g' )"
    git_command "$GIT_REPO" "fetch";
    local RESULT=$( git --git-dir="$GIT_REPO" --work-tree="$WORK_TREE" remote show origin | grep 'tracked' | grep "$BRANCH" 2>/dev/null )
    if [[ -n "$RESULT" ]];
    then
      if [[ -z $( git --git-dir="$GIT_REPO" --work-tree="$WORK_TREE" branch | grep '*' | grep "$BRANCH" ) ]];
      then
        git_command "$GIT_REPO" "checkout $BRANCH";
        echo "Changed $GIT_REPO to branch $BRANCH";
      else
        echo "Already on branch $BRANCH";
      fi
    else
      echo "$GIT_REPO does not have branch $BRANCH... Ignoring...";
    fi
  done
}

inputloop