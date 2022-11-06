#!/bin/bash

cd "$(dirname "$0")" || exit 1

twbin=teeworlds_srv
rubybin=send_chat_hello.rb
srvcfg='sv_rcon_password rcon;sv_port 8377;killme'

function cleanup() {
	echo "[*] shutting down server ..."
	pkill -f "$twbin $srvcfg"
	[[ "$_timout_pid" != "" ]] && kill "$_timout_pid" &> /dev/null
}

trap cleanup EXIT

function timeout() {
	local seconds="$1"
	sleep "$seconds"
	pkill -f "$rubybin"
	echo "killing: $rubybin"
	echo "Error: timeouted"
}

if [[ -x "$(command -v teeworlds_srv)" ]]
then
	teeworlds_srv "$srvcfg" &> server.txt &
elif [[ -x "$(command -v teeworlds-server)" ]]
then
	teeworlds-server "$srvcfg" &> server.txt &
	twbin='teeworlds-server'
elif [[ -x "$(command -v teeworlds-srv)" ]]
then
	teeworlds-srv "$srvcfg" &> server.txt &
	twbin='teeworlds-srv'
else
	echo "Error: please install a teeworlds_srv"
	exit 1
fi

testname="${1:-chat}"
echo "[*] running test '$testname' ..."

if [ "$testname" == "chat" ]
then
	rubybin=send_chat_hello.rb
elif [ "$testname" == "reconnect" ]
then
	rubybin=reconnect.rb
elif [ "$testname" == "rcon" ]
then
	rubybin=rcon_shutdown.rb
else
	echo "Error: unkown test '$testname'"
	exit 1
fi

timeout 3 killme &
_timout_pid=$!

function fail() {
	local msg="$1"
	tail client.txt
	tail server.txt
	echo "$msg"
	exit 1
}

if [ "$testname" == "chat" ]
then
	ruby "$rubybin" &> client.txt

	if ! grep -q 'hello world' server.txt
	then
		fail "Error: did not find chat message in server log"
	fi
elif [ "$testname" == "reconnect" ]
then
	ruby "$rubybin" &> client.txt

	if ! grep -q 'bar' server.txt
	then
		fail "Error: did not find 2nd chat message in server log"
	fi
elif [ "$testname" == "rcon" ]
then
	ruby "$rubybin" &> client.txt

	if pgrep -f "$twbin $srvcfg"
	then
		fail "Error: server still running rcon shutdown failed"
	fi
else
	echo "Error: unkown test '$testname'"
	exit 1
fi

echo "[+] Test passed"

