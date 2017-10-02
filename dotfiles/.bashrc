function giit() {
	find ~/workspace -type d -name .git | parallel -j20 "cd \"{.}\" && printf \"%-60s %10s\\n\" \"{.}\" \"$( git $@ )\";";
}

# Aliases
alias oclogin="oc login https://192.168.64.2:8443 --token=7kS7Bns2HMsFr1l5Yo0vucixJvQEEoOKM9T3mfQNDCw"
alias update='brew update -y && brew upgrade -y && brew cleanup -s -force && softwareupdate -ia'
