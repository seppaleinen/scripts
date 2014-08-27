RADIUS=6371;

function squareroot() {
	local NUMBER="$1"
	echo "sqrt($NUMBER)" | bc -l
}

function tan() {
	local NUMBER="$1"
	echo "a($NUMBER)" | bc -l
}

function cos() {
	local NUMBER="$1"
	echo "c($NUMBER)" | bc -l
}

function sin() {
	local NUMBER="$1"
	echo "s($NUMBER)" | bc -l
}

function calculateDistanceBetween() {
	echo ONE: "$1"
	echo TWO: "$2"

	local LATITUDE_ONE=$( echo "$1" | awk -F':' '{print $1}' )
	local LONGITUDE_ONE=$( echo "$1" | awk -F':' '{print $2}' )

	local LATITUDE_TWO=$( echo "$2" | awk -F':' '{print $1}' )
	local LONGITUDE_TWO=$( echo "$2" | awk -F':' '{print $2}' )

	local LATITUDE_DELTA=$( echo $LATITUDE_TWO - $LATITUDE_ONE | bc -l );
	local LONGITUDE_DELTA=$( echo $LONGITUDE_TWO - $LONGITUDE_ONE | bc -l );

	local SINUS_LAT=$( sin $( echo $LATITUDE_DELTA / 2 | bc -l ) );
	local SINUS_LAT_TIMES_TWO=$( echo "$SINUS_LAT * $SINUS_LAT" | bc -l );

	local COSINUS=$( cos $LATITUDE_DELTA );
	local COSINUS_TIMES_TWO=$( echo "$COSINUS * $COSINUS" | bc -l );

	local SINUS_LNG=$( sin $( echo $LONGITUDE_DELTA / 2 | bc -l ) )
	local SINUS_LNG_TIMES_TWO=$( echo "$SINUS_LNG * $SINUS_LNG" | bc -l );

	local a=$( echo "$SINUS_LAT_TIMES_TWO + $COSINUS_TIMES_TWO * $SINUS_LNG_TIMES_TWO" | bc -l )

	local SQUARE_A=$( squareroot $a );
	local SQUARE_1_MINUS_A=$( squareroot $( echo "1 - $a" | bc -l ) );
	local TAN_SQUARES=$( echo - | awk "{print atan2($SQUARE_A, $SQUARE_1_MINUS_A)}" );
	local TAN_SQUARES_TIMES_TWO=$( echo "$TAN_SQUARES * $TAN_SQUARES" | bc -l );

	local c=$( echo "$RADIUS * $TAN_SQUARES_TIMES_TWO" | bc -l );

	echo c $c;

	#local b = $(( 2 * tan( $(( squareroot($a), squareroot(1-$a)) ))
	#echo "b = $b"
	#c = RADIUD * b;

}



function getLocationFromAddress() {
	local ADDRESS="$1"
	local URL="http://maps.googleapis.com/maps/api/geocode/xml?address=$ADDRESS&sensor=false"
	local RESULT=$( wget -qO- "$URL" | grep -A2 '<location>' )
	local LATITUDE=$( echo $RESULT | awk -F'<lat>' '{print $2}' | awk -F'</lat>' '{print $1}' )
	local LONGITUDE=$( echo $RESULT | awk -F'<lng>' '{print $2}' | awk -F'</lng>' '{print $1}' )
	local LOCATION="$LATITUDE:$LONGITUDE"
	echo $LOCATION
}

function compareAddresses() {
	local LOCATION1=$( getLocationFromAddress "$ADDRESS1" )
	local LOCATION2=$( getLocationFromAddress "$ADDRESS2" )

	calculateDistanceBetween "$LOCATION1" "$LOCATION2"
}

echo "Write an address";
read ADDRESS1
echo "Write another address";
read ADDRESS2

compareAddresses;