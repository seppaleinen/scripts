function getRss() {
  #local REVERSED_RSS="$( curl -s 'http://vioxx/jenkins-build/rssAll' | xmllint --format - | grep -n '' | sed 's/jenkins/jenkins-build/g' | sed 's/job/view\/Deploy\/job/g' | sort -r -n | sed 's/^[0-9]*://g' )"
  local RSS="$( curl -s 'http://vioxx/jenkins-build/rssAll' | xmllint --format - | sed 's/jenkins/jenkins-build/g' | sed 's/job/view\/Deploy\/job/g' )"
  IFS=$'\n'
  for ROW in $RSS
  do
    echo "$ROW"
  done
}
getRss
