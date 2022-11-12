#!/bin/bash

cd "$(dirname "$0")" || exit 1

tw_srv_bin=teeworlds_srv
tw_cl_bin=teeworlds
srvcfg='sv_rcon_password rcon;sv_port 8377;killme'
clcfg='connect 127.0.0.1:8377;killme'
tw_srv_running=0
tw_client_running=0
logdir=logs

mkdir -p logs

function start_tw_server() {
	if [[ -x "$(command -v teeworlds_srv)" ]]
	then
		teeworlds_srv "$srvcfg" &> "$logdir/server.txt" &
	elif [[ -x "$(command -v teeworlds-server)" ]]
	then
		teeworlds-server "$srvcfg" &> "$logdir/server.txt" &
		tw_srv_bin='teeworlds-server'
	elif [[ -x "$(command -v teeworlds-srv)" ]]
	then
		teeworlds-srv "$srvcfg" &> "$logdir/server.txt" &
		tw_srv_bin='teeworlds-srv'
	else
		echo "Error: please install a teeworlds_srv"
		exit 1
	fi
	tw_srv_running=1
}

function connect_tw_client() {
	if [[ -x "$(command -v teeworlds)" ]]
	then
		teeworlds "$clcfg"
		tw_cl_bin=teeworlds
	else
		echo "Error: please install a teeworlds"
		exit 1
	fi
	tw_client_running=1
}

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

function cleanup() {
	if [ "$tw_srv_running" == "1" ]
	then
		echo "[*] shutting down server ..."
		pkill -f "$tw_srv_bin $srvcfg"
	fi
	if [ "$tw_client_running" == "1" ]
	then
		echo "[*] shutting down client ..."
		pkill -f "$tw_cl_bin $clcfg"
	fi
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
	tail "$logdir/ruby_client.txt" &>/dev/null
	echo "[-] end of ruby client log:"
	tail "$logdir/ruby_client.txt"
	echo "[-] end of server log:"
	tail "$logdir/server.txt"
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

echo "[*] running test '$testname' ..."
echo "ruby client log $(date)" > "$logdir/ruby_client.txt"
echo "server log $(date)" > "$logdir/server.txt"
[[ -f timeout.txt ]] && rm timeout.txt
start_tw_server
timeout 3 killme &
_timout_pid=$!
ruby "$testname" killme &> "$logdir/ruby_client.txt"

if [ "$testname" == "client/chat.rb" ]
then
	if ! grep -q 'hello world' "$logdir/server.txt"
	then
		fail "Error: did not find chat message in server log"
	fi
elif [ "$testname" == "client/reconnect.rb" ]
then
	if ! grep -q 'bar' "$logdir/server.txt"
	then
		fail "Error: did not find 2nd chat message in server log"
	fi
elif [ "$testname" == "client/rcon.rb" ]
then
	sleep 1
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

