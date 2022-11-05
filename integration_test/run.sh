#!/bin/bash

cd "$(dirname "$0")" || exit 1

twbin=teeworlds_srv

function cleanup() {
	echo "[*] shutting down server ..."
	pkill -f "$twbin sv_port 8377;killme"
	[[ "$_timout_pid" != "" ]] && kill "$_timout_pid" &> /dev/null
}

trap cleanup EXIT

function timeout() {
	local seconds="$1"
	sleep "$seconds"
	pkill -f 'send_chat_hello.rb'
	echo "Error: timeouted"
}

if [[ -x "$(command -v teeworlds_srv)" ]]
then
	teeworlds_srv "sv_port 8377;killme" &> server.txt &
elif [[ -x "$(command -v teeworlds-server)" ]]
then
	teeworlds-server "sv_port 8377;killme" &> server.txt &
	twbin='teeworlds-server'
elif [[ -x "$(command -v teeworlds-srv)" ]]
then
	teeworlds-srv "sv_port 8377;killme" &> server.txt &
	twbin='teeworlds-srv'
else
	echo "Error: please install a teeworlds_srv"
	exit 1
fi
timeout 3 killme &
_timout_pid=$!

testname="${1:-chat}"

echo "[*] running test '$testname' ..."

function fail() {
	local msg="$1"
	tail client.txt
	tail server.txt
	echo "$msg"
	exit 1
}

if [ "$testname" == "chat" ]
then
	ruby ./send_chat_hello.rb &> client.txt

	if ! grep -q 'hello world' server.txt
	then
		fail "Error: did not find chat message in server log"
	fi
elif [ "$testname" == "reconnect" ]
then
	ruby ./reconnect.rb &> client.txt

	if ! grep -q 'bar' server.txt
	then
		fail "Error: did not find 2nd chat message in server log"
	fi
else
	echo "Error: unkown test '$testname'"
	exit 1
fi

echo "[+] Test passed client sent chat message to server"

