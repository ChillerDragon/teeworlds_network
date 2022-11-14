#!/bin/bash

cd "$(dirname "$0")" || exit 1

tw_srv_bin=teeworlds_srv
tw_cl_bin=teeworlds
srvcfg='sv_rcon_password rcon;sv_port 8377;killme'
clcfg='connect 127.0.0.1:8377;killme'
tw_srv_running=0
tw_client_running=0
logdir=logs
ruby_logfile=ruby_client.txt

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
	if [[ -x "$(command -v teeworlds-headless)" ]]
	then
		teeworlds-headless "$clcfg" "$logdir/client.txt"
		tw_cl_bin=teeworlds-headless
	elif [[ -x "$(command -v /usr/local/bin/teeworlds-headless)" ]]
	then
		/usr/local/bin/teeworlds-headless "$clcfg" "$logdir/client.txt"
		tw_cl_bin=/usr/local/bin/teeworlds-headless
	elif [[ -x "$(command -v teeworlds)" ]]
	then
		teeworlds "$clcfg" "$logdir/client.txt"
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
if [[ "$testname" =~ ^client/ ]]
then
	ruby_logfile="$logdir/ruby_client.txt"
else
	ruby_logfile="$logdir/ruby_server.txt"
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
	tail "$ruby_logfile" &>/dev/null
	echo "[-] end of ruby client log:"
	tail "$ruby_logfile"
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
[[ -f timeout.txt ]] && rm timeout.txt
if [[ "$testname" =~ ^client/ ]]
then
	echo "ruby client log $(date)" > "$ruby_logfile"
	echo "server log $(date)" > "$logdir/server.txt"
	start_tw_server
else
	echo "client log $(date)" > "$logdir/client.txt"
	echo "server log $(date)" > "$ruby_logfile"
	connect_tw_client
fi
timeout 3 killme &
_timout_pid=$!
ruby "$testname" killme &> "$ruby_logfile"

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
elif [ "$testname" == "client/multiple_blocks.rb" ]
then
	sleep 1
	if pgrep -f "$tw_srv_bin $srvcfg"
	then
		fail "Error: server still running rcon shutdown failed (2 blocks)"
	fi
	block1_ln="$(grep -n "block 1" "$ruby_logfile" | cut -d':' -f1)"
	block2_ln="$(grep -n "block 2" "$ruby_logfile" | cut -d':' -f1)"
	if [ "$block1_ln" == "" ]
	then
		fail "Error: 'block 1' not found in client log"
	fi
	if [ "$block2_ln" == "" ]
	then
		fail "Error: 'block 2' not found in client log"
	fi
	if [[ ! "$block1_ln" =~ ^[0-9]+$ ]]
	then
		fail "Error: failed to parse line number of 'block 1' got='$block1_ln'"
	fi
	if [[ ! "$block2_ln" =~ ^[0-9]+$ ]]
	then
		fail "Error: failed to parse line number of 'block 2' got='$block2_ln'"
	fi
	# ensure block call order matches definition order
	if [ "$block1_ln" -gt "$block2_ln" ]
	then
		fail "Error: 'block 1' found after 'block 2' in client log"
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

