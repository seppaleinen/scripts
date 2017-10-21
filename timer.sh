#!/usr/bin/env bash

command="$*";
iterations=5;
totaltime=0;
IFS=$'\n';
for i in $( seq 1 "$iterations" ); do
    result=$( eval "$command" | grep 'Total time' | awk -F'time: ' '{print $2}' | awk -F' s' '{print $1}' );
    totaltime=$( echo "$result+$totaltime" | bc -l );
    avgtime=$( echo "$totaltime/$i" | bc -l )
    printf "Resulting time: %.3f, average time: %.3f, for iteration %s\\n" "$result" "$avgtime" "$i";
done

printf "Result: %.3f\\n" "$( echo "$totaltime/$iterations" | bc -l )"