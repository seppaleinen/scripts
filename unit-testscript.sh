#! /bin/sh

testEquality(){
  	assertEquals 1 2
}

test(){
	./git.sh
}

# load shunit2
. ./shunit