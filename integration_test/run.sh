#!/bin/bash

cd "$(dirname "$0")" || exit 1

tw_srv_bin=teeworlds_srv
tw_cl_bin=teeworlds
srvcfg='sv_rcon_password rcon;sv_port 8377;killme'

if [[ -x "$(command -v teeworlds_srv)" ]]
then
	teeworlds_srv "$srvcfg" &> server.txt &
elif [[ -x "$(command -v teeworlds-server)" ]]
then
	teeworlds-server "$srvcfg" &> server.txt &
	tw_srv_bin='teeworlds-server'
elif [[ -x "$(command -v teeworlds-srv)" ]]
then
	teeworlds-srv "$srvcfg" &> server.txt &
	tw_srv_bin='teeworlds-srv'
else
	echo "Error: please install a teeworlds_srv"
	exit 1
fi

if [[ ! -x "$(command -v "$tw_cl_bin")" ]]
then
	echo "Error: please install a teeworlds"
	exit 1
fi

function get_test_names() {
	(find client -name "*.rb";find server -name "*.rb") | tr '\n' ' '
}
function invalid_test() {
	local name="$1"
	echo "Error: invalid test name '$name'"
	echo "       valid tests: $(get_test_names)"
	exit 1
}

testname="${1:-client/chat.rb}"

if ! [[ "$testname" =~ (client|server)/.*\.rb$ ]]
then
	invalid_test "$testname"
fi
if [ ! -f "$testname" ]
then
	testname=${testname##*integration_test/}
	if [ ! -f "$testname" ]
	then
		invalid_test "$testname"
	fi
fi

echo "[*] running test '$testname' ..."
echo "client log $(date)" > client.txt
echo "server log $(date)" > server.txt
[[ -f timeout.txt ]] && rm timeout.txt

function cleanup() {
	echo "[*] shutting down server ..."
	pkill -f "$tw_srv_bin $srvcfg"
	[[ "$_timout_pid" != "" ]] && kill "$_timout_pid" &> /dev/null
}

trap cleanup EXIT

function fail() {
	local msg="$1"
	# the first tail get swalloed
	# idk why so tail twice to ensure
	# getting output
	# this is a bit ugly but it works
	# maybe a sleep does as well
	# or I still did not get flushing
	tail client.txt &>/dev/null
	echo "[-] end of client log:"
	tail client.txt
	echo "[-] end of server log:"
	tail server.txt
	echo "$msg"
	exit 1
}

function timeout() {
	local seconds="$1"
	sleep "$seconds"
	echo "[-] Timeout -> killing: $testname"
	touch timeout.txt
	pkill -f "$testname killme"
	fail "[-] Timeout"
}


timeout 3 killme &
_timout_pid=$!

if [ "$testname" == "client/chat.rb" ]
then
	ruby "$testname" killme &> client.txt

	if ! grep -q 'hello world' server.txt
	then
		fail "Error: did not find chat message in server log"
	fi
elif [ "$testname" == "client/reconnect.rb" ]
then
	ruby "$testname" killme &> client.txt

	if ! grep -q 'bar' server.txt
	then
		fail "Error: did not find 2nd chat message in server log"
	fi
elif [ "$testname" == "client/rcon.rb" ]
then
	ruby "$testname" killme &> client.txt

	sleep 0.1
	if pgrep -f "$tw_srv_bin $srvcfg"
	then
		fail "Error: server still running rcon shutdown failed"
	fi
else
	echo "Error: unkown test '$testname'"
	exit 1
fi

if [ -f timeout.txt ]
then
	echo "[-] Error timouted"
	exit 1
fi

echo "[+] Test passed"

