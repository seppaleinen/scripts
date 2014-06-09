function changeStandaloneToEnv(){
	local STP="$1"	
	local ENV="$2"
	#Check that $STP && $ENV is not empty and $STP is existing file
	if [[ -n "$STP" && -n "$ENV" && -n "$( find "$STP" -type f 2>/dev/null )" ]]; then
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
		esac
		#change SERVICE_NAME = ? to $ENV and HOST = ? to $HOSTENV
		sed -i -e "s/SERVICE_NAME = \w\{2,4\}/SERVICE_NAME = $ENV/g" -e "s/HOST = [a-zA-Z0-9.-]\{4,200\}/HOST = $HOSTENV/g" "$STP" 
	fi
}

if [[ -n "$1" && -n "$2" ]]; then
	changeStandaloneToEnv "$1" "$2"
fi
