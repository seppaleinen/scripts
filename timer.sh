function getTime() {
echo $(($(date +'%s + %-N / 1000')))
}

TIME=0;
for i in {1..10};
do 
DATE=$( getTime );
RESULT=$( find ~/IdeaProjects -type d -name .git -exec sh -c 'TREE=$( echo {} | sed "s_\.git__g" ); git --git-dir={} --work-tree=$TREE remote show origin;' \; );
DATE2=$( getTime );
RESULT_TIME=$( echo $DATE2 - $DATE | bc -l );
echo $RESULT_TIME
TIME=$( echo $TIME + $RESULT_TIME | bc -l );
done;

echo "Find" $( echo $TIME / 10 | bc -l );

TIME=0;
for i in {1..10};
do 
DATE=$( getTime );
for DIR in $( find ~/IdeaProjects -type d -name .git );
do
WORK=$( echo $DIR | sed 's_\.git__g' );
RESULT=$( git --git-dir=$DIR --work-tree=$WORK remote show origin );
done;
DATE2=$( getTime );
RESULT_TIME=$( echo $DATE2 - $DATE | bc -l );
echo $RESULT_TIME
TIME=$( echo $TIME + $RESULT_TIME | bc -l );
done;

echo "For" $( echo $TIME / 10 | bc -l ); 