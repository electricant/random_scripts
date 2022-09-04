#/bin/sh

testFunction() {
	sleep 2
	echo nap done. Time to do something
	sleep 1
}

testFunction &
exec time
# is not fun
testFunction
