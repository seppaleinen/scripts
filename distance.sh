RADIUS=6371;
PI=3.141592653589793238462643383279;
d2r=0.017453292519943295;

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
	echo "c($NUMBER)" | bc -l | sed 's_^\._0\._g'
}

function sin() {
	local NUMBER="$1"
	echo "s($NUMBER)" | bc -l | sed 's_^\._0\._g'
}

function toRadian() {
	local DEGREES="$1"
	#local PI=$(echo "scale=10; 4*a(1)" | bc -l)
	#local d2r=$( echo "" | awk "END { print $PI / 180 }" )
	echo "$DEGREES * $d2r" | bc -l | sed 's_^\._0\._g'  
}

function haversineFormula() {
	local LATITUDE_1="$1";
	local LATITUDE_2="$2";
	local LATITUDE_DELTA="$3";
	local LONGITUDE_DELTA="$4";

	local SINUS_LAT=$( sin $( echo $LATITUDE_DELTA / 2 | bc -l ) );
	local SINUS_LAT_TIMES_TWO=$( echo "" | awk "END {print $SINUS_LAT ^ $SINUS_LAT }" );

	local COSINUS=$( cos $LATITUDE_DELTA );
	local COSINUS_TIMES_TWO=$( echo "$COSINUS * $COSINUS" | bc -l | sed 's_^\._0\._g' );

	local SINUS_LNG=$( sin $( echo $LONGITUDE_DELTA / 2 | bc -l | sed 's_^\._0\._g' ) );
	local SINUS_LNG_TIMES_TWO=$( echo "" | awk "END {print $SINUS_LNG ^ $SINUS_LNG }" );

	local a=$( echo "$SINUS_LAT_TIMES_TWO + $COSINUS_TIMES_TWO * $SINUS_LNG_TIMES_TWO" | bc -l );

	local SQUARE_A=$( squareroot $a );
	local SQUARE_1_MINUS_A=$( squareroot $( echo "1 - $a" | bc -l ) );
	local TAN_SQUARES=$( echo - | awk "{print atan2($SQUARE_A, $SQUARE_1_MINUS_A)}" | awk {' printf "%4.10f", $1 '} );
	local TAN_SQUARES_TIMES_TWO=$( echo "$TAN_SQUARES * $TAN_SQUARES" | bc -l );

	local c=$( echo "$RADIUS * $TAN_SQUARES_TIMES_TWO" | bc -l );

	echo $c;
}

function calculateDistanceBetween() {
	local LATITUDE_ONE=$( echo "$1" | awk -F':' '{print $1}' );
	local LONGITUDE_ONE=$( echo "$1" | awk -F':' '{print $2}' );

	local LATITUDE_TWO=$( echo "$2" | awk -F':' '{print $1}' );
	local LONGITUDE_TWO=$( echo "$2" | awk -F':' '{print $2}' );

	local LATITUDE_ONE_RADIUS=$( toRadian $LATITUDE_ONE );
	local LATITUDE_TWO_RADIUS=$( toRadian $LATITUDE_TWO );

	local LATITUDE_DELTA=$( echo "" | awk "END {print $LATITUDE_TWO - $LATITUDE_ONE }" | sed 's_^\._0\._g'  );
	local LONGITUDE_DELTA=$( echo "" | awk "END {print $LONGITUDE_TWO - $LONGITUDE_ONE }" | sed 's_^\._0\._g'  );

	local LATITUDE_DELTA_RADIUS=$( toRadian $LATITUDE_DELTA );
	local LONGITUDE_DELTA_RADIUS=$( toRadian $LONGITUDE_DELTA );

	local RESULT=$( haversineFormula $LATITUDE_ONE_RADIUS $LATITUDE_TWO_RADIUS $LATITUDE_DELTA_RADIUS $LONGITUDE_DELTA_RADIUS );

	echo $RESULT;
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