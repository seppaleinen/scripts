#! /bin/sh

testEquality(){
  	assertEquals 1 1
}

test(){
	./git.sh
}

# load shunit2
. ./shunit
