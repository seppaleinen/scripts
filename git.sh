function gitCommand(){
	local GIT_REPO="$1"
	local COMMAND="$2"
	local GIT_DIR="$( echo $GIT_REPO | sed 's/\.git//g' )"
	git --git-dir="$GIT_REPO" --work-tree="$GIT_DIR" $COMMAND
	#echo '(out of date)'
}
function successMessage(){
	local BUILD_MESSAGE="$1"
	local BUILD_ARTIFACT="$2"
	if [[ -n "$BUILD_MESSAGE" ]]; then
		echo "$BUILD_ARTIFACT" build complete
	else
		echo "$BUILD_ARTIFACT" build failure
	fi
}
function buildMaven(){
	local POM_FILE="$( echo $1 | sed 's/\.git/pom.xml/g' )"
	local FILE_EXIST="$( find $POM_FILE -type f 2>/dev/null )"
	if [[ -n "$FILE_EXIST" ]]; then
		local SUCCESS="$( mvn -f "$POM_FILE" clean install 2>/dev/null | grep 'BUILD SUCCESS' )"
		successMessage "$SUCCESS" "$POM_FILE"
	fi
}
function buildGradle(){
	local GRADLE_BUILD_FILE="$( echo $1 | sed 's/\.git/build.gradle/g' )"
	local GRADLE_SETTINGS_FILE="$( echo $1 | sed 's/\.git/settings.gradle/g' )"
	local BUILD_FILE_EXIST="$( find $GRADLE_BUILD_FILE -type f 2>/dev/null )"
	if [[ -n "$BUILD_FILE_EXIST" ]]; then
		local SETTINGS_FILE_EXIST="$( find $GRADLE_SETTINGS_FILE -type f 2>/dev/null )"
		if [[ -n "$SETTINGS_FILE_EXIST" ]]; then
			local SUCCESS="$( gradle -b $GRADLE_BUILD_FILE -c $GRADLE_SETTINGS_FILE clean build | grep 'BUILD SUCCESSFUL' )"
			successMessage "$SUCCESS" "$GRADLE_BUILD_FILE"
		else
			local SUCCESS="$( gradle -b $GRADLE_BUILD_FILE clean build | grep 'BUILD SUCCESSFUL' )"
			successMessage "$SUCCESS" "$GRADLE_BUILD_FILE"
		fi
	fi
}
function build(){
	local GIT_ARTIFACT_REPO="$1"
	local GRADLE_FILE_EXIST="$( find $( echo $GIT_ARTIFACT_REPO | sed 's/\.git/build.gradle/g' ) -type f 2>/dev/null )"
	local MAVEN_FILE_EXIST="$( find $( echo $GIT_ARTIFACT_REPO | sed 's/\.git/pom.xml/g' ) -type f 2>/dev/null )"
	if [[ -n "$MAVEN_FILE_EXIST" ]]; then
		buildMaven "$GIT_ARTIFACT_REPO"
	fi
	if [[ -n "$GRADLE_FILE_EXIST" ]]; then
		buildGradle "$GIT_ARTIFACT_REPO"
	fi	
}
function checkGitRepos(){
	local ARTIFACT="$1"
	local SEARCH_DIR=~/IdeaProjects
	if [[ -n "$ARTIFACT" ]]; then
		SEARCH_DIR=$( echo $SEARCH_DIR/$ARTIFACT )
	fi
	local GIT_REPO_LIST="$( find $SEARCH_DIR -type d -name .git 2>/dev/null )"
	if [[ -n "$GIT_REPO_LIST" ]]; then
		for GIT_REPO in $GIT_REPO_LIST
		do
			local OUT_OF_DATE=$( gitCommand "$GIT_REPO" "remote show origin" |  grep '(out of date)' )
			if [[ -n "$OUT_OF_DATE" ]]; then
				gitCommand "$GIT_REPO" "pull"
				build "$GIT_REPO"
			else
				echo Gitrepo "$GIT_REPO" is up to date
			fi
		done
	else
		echo no git repository present in "$SEARCH_DIR"
	fi
}
checkGitRepos "$1"