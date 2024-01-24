#!/bin/bash

cd "$(dirname "$0")" || exit 1

tw_srv_bin=teeworlds_srv
logdir=logs
tmpdir=tmp
kill_marker=kill_me_d5af0410
server_port=8377
srvcfg="sv_rcon_password rcon;sv_port $server_port;$kill_marker"
cl_fifo="$PWD/$tmpdir/client.fifo"
clcfg="cl_input_fifo $cl_fifo;connect 127.0.0.1:$server_port;player_name test_client;$kill_marker"
tw_srv_running=0
ruby_logfile=ruby_client.txt
ruby_logfile_err=ruby_client_stderr.txt

_client_pid=''
_kill_pids=()

mkdir -p logs
mkdir -p tmp

start_tw_server() {
	if [[ -x "$(command -v teeworlds_srv)" ]]
	then
		teeworlds_srv "$srvcfg" &> "$logdir/server.txt"
	elif [[ -x "$(command -v teeworlds-server)" ]]
	then
		teeworlds-server "$srvcfg" &> "$logdir/server.txt"
		tw_srv_bin='teeworlds-server'
	elif [[ -x "$(command -v teeworlds-srv)" ]]
	then
		teeworlds-srv "$srvcfg" &> "$logdir/server.txt"
		tw_srv_bin='teeworlds-srv'
	else
		echo "Error: please install a teeworlds_srv"
		exit 1
	fi
	tw_srv_running=1
}

connect_tw_client() {
	if [[ -x "$(command -v teeworlds-headless)" ]]
	then
		teeworlds-headless "$clcfg"
	elif [[ -x "$(command -v /usr/local/bin/teeworlds-headless)" ]]
	then
		/usr/local/bin/teeworlds-headless "$clcfg"
	elif [[ -x "$(command -v teeworlds)" ]]
	then
		teeworlds "$clcfg" "$logdir/client.txt"
	else
		echo "Error: please install a teeworlds"
		exit 1
	fi
}

connect_ddnet7_client() {
	local clcfg_dd7
	clcfg_dd7="$(echo "$clcfg" | sed 's/127.0.0.1/tw-0.7+udp:\/\/127.0.0.1/')"
	if [[ -x "$(command -v DDNet7-headless)" ]]
	then
		DDNet7-headless "$clcfg_dd7"
	elif [[ -x "$(command -v /usr/local/bin/DDNet7-headless)" ]]
	then
		/usr/local/bin/DDNet7-headless "$clcfg_dd7"
	else
		echo "Error: please install a DDNet7-headless"
		exit 1
	fi
}

get_test_names() {
	(find client -name "*.rb";find server -name "*.rb") | tr '\n' ' '
}
invalid_test() {
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
	ruby_logfile_err="$logdir/ruby_client_stderr.txt"
else
	ruby_logfile="$logdir/ruby_server.txt"
	ruby_logfile_err="$logdir/ruby_server_stderr.txt"
fi

kill_all_jobs() {
	local i
	local kill_pid
	for i in "${!_kill_pids[@]}"
	do
		kill_pid="${_kill_pids[i]}"
		[[ "$kill_pid" != "" ]] || continue
		ps -p "$kill_pid" > /dev/null || continue

		kill "$kill_pid" &> /dev/null
		_kill_pids[i]='' # does not work because different job
	done
	pkill -f "$kill_marker"
}

cleanup() {
	if [ "$tw_srv_running" == "1" ]
	then
		echo "[*] shutting down server ..."
		pkill -f "$tw_srv_bin $srvcfg"
	fi
	kill_all_jobs
	# timeout is extra otherwise it kills it self
	[[ "$_timeout_pid" != "" ]] && ps -p "$_timeout_pid" >/dev/null && kill "$_timeout_pid"
}

trap cleanup EXIT

fail() {
	local msg="$1"
	if [ ! -f "$tmpdir/fail.txt" ]
	then
		touch "$tmpdir/fail.txt"
		# the first tail get swalloed
		# idk why so tail twice to ensure
		# getting output
		# this is a bit ugly but it works
		# maybe a sleep does as well
		# or I still did not get flushing
		tail "$ruby_logfile" &>/dev/null
		tail "$ruby_logfile_err" &>/dev/null
		if [[ "$testname" =~ ^client/ ]]
		then
			echo "[-] end of ruby client log:"
			tail -n 10 "$ruby_logfile"
			echo "[-] end of server log:"
			tail "$logdir/server.txt"
		else
			echo "[-] end of ruby server log:"
			cat "$ruby_logfile"
			echo "[-] end of client log:"
			cat "$logdir/client.txt"
		fi
		if [ ! -s "$ruby_logfile_err" ]
		then
			echo "[-] got ruby stderr $ruby_logfile_err"
			cat "$ruby_logfile_err"
		fi
	fi
	echo "[-][FATAL] $msg"
	exit 1
}

timeout() {
	local seconds="$1"
	sleep "$seconds"
	echo "[-] Timeout -> killing: $testname"
	touch "$tmpdir/timeout.txt"
	kill_all_jobs
	fail "Timeout"
}

echo "[*] running test '$testname' ..."
[[ -f "$tmpdir/timeout.txt" ]] && rm "$tmpdir"/timeout.txt
[[ -f "$tmpdir/fail.txt" ]] && rm "$tmpdir"/fail.txt
:>"$ruby_logfile_err"
if [[ "$testname" =~ ^client/ ]]
then
	echo "ruby client log $(date)" > "$ruby_logfile"
	echo "server log $(date)" > "$logdir/server.txt"
	start_tw_server &
	_kill_pids+=($!)
else
	echo "ddnet7 client log $(date)" > "$logdir/client.txt"
	echo "ruby server log $(date)" > "$ruby_logfile"
fi
run_ruby_test() {
	if ! ruby "$testname" "$kill_marker" 2> "$ruby_logfile_err" 1> "$ruby_logfile"
	then
		fail "test $testname finished with non zero exit code"
	fi
}
if [[ "$testname" =~ ^server/ ]]
then
	run_ruby_test &
	_kill_pids+=($!)
else
	run_ruby_test
	kill_all_jobs
fi

if [[ "$testname" =~ ^server/ ]]
then
	connect_ddnet7_client "$kill_marker" &>> "$logdir/client.txt" &
	_client_pid=$!
	_kill_pids+=("$_client_pid")
	sleep 1
fi
timeout 20 "$kill_marker" &
_timeout_pid=$!

fifo() {
	local cmd="$1"
	local fifo_file="$2"
	echo "[*] $cmd >> $fifo_file"
	echo "$cmd" >> "$fifo_file"
}
assert_in_log() {
	# usage: assert_in_log string path [num_matches"
	# examples:
	#   assert_in_log "string to find" "/path/to/log.txt"
	#   assert_in_log "string to find" "/path/to/log.txt" 2
	local needle="$1"
	local logfile_path="$2"
	local num_matches="$3"
	if ! grep -qF "$needle" "$logfile_path"
	then
		echo "[-] Error: did not find expected string in logs"
		echo "[-]"
		echo "[-]  expected: $needle"
		echo "[-]  in  file: $ruby_logfile"
		echo "[-]"
		fail "assert failed"
	fi
	if [ "$num_matches" != "" ]
	then
		local actual_matches
		actual_matches="$(grep -cF "$needle" "$logfile_path")"
		if [ "$actual_matches" != "$num_matches" ]
		then
			echo "[-] Error: found string unexpected amount of times in log file"
			echo "[-]"
			echo "[-]  expected: $needle"
			echo "[-]  in  file: $ruby_logfile"
			echo "[-]"
			echo "[-]  expected num hits: $num_matches"
			echo "[-]       got num hits: $actual_matches"
			echo "[-]"
			fail "assert failed"
		fi
	fi
	echo "[*] $needle .. OK"
}

if [ "$testname" == "client/chat.rb" ]
then
	if ! grep -q 'hello world' "$logdir/server.txt"
	then
		fail "did not find chat message in server log"
	fi
elif [ "$testname" == "client/reconnect.rb" ]
then
	if ! grep -q 'bar' "$logdir/server.txt"
	then
		fail "did not find 2nd chat message in server log"
	fi
elif [ "$testname" == "client/rcon.rb" ]
then
	sleep 1
	if pgrep -f "$tw_srv_bin $srvcfg"
	then
		fail "server still running rcon shutdown failed"
	fi
elif [ "$testname" == "client/srv_say.rb" ]
then
	if ! grep -q '^\[chat\].*hello' "$logdir/ruby_client.txt"
	then
		fail "missing 'hello' chat message in client log"
	fi
elif [ "$testname" == "client/multiple_blocks.rb" ]
then
	sleep 1
	if pgrep -f "$tw_srv_bin $srvcfg"
	then
		fail "server still running rcon shutdown failed (2 blocks)"
	fi
	block1_ln="$(grep -n "block 1" "$ruby_logfile" | cut -d':' -f1)"
	block2_ln="$(grep -n "block 2" "$ruby_logfile" | cut -d':' -f1)"
	if [ "$block1_ln" == "" ]
	then
		fail "'block 1' not found in client log"
	fi
	if [ "$block2_ln" == "" ]
	then
		fail "'block 2' not found in client log"
	fi
	if [[ ! "$block1_ln" =~ ^[0-9]+$ ]]
	then
		fail "failed to parse line number of 'block 1' got='$block1_ln'"
	fi
	if [[ ! "$block2_ln" =~ ^[0-9]+$ ]]
	then
		fail "failed to parse line number of 'block 2' got='$block2_ln'"
	fi
	# ensure block call order matches definition order
	if [ "$block1_ln" -gt "$block2_ln" ]
	then
		fail "'block 1' found after 'block 2' in client log"
	fi
elif [ "$testname" == "server/connect.rb" ]
then
	fifo "rcon_auth test" "$cl_fifo"
	sleep 1
	fifo "rcon shutdown" "$cl_fifo"
	sleep 1
	fifo "quit" "$cl_fifo"
	# ddnet quitting can get stuck so send a kill to ensure it dies
	kill "$_client_pid"

	assert_in_log "'test_client' joined the game" "$ruby_logfile" 1
	assert_in_log "rcon='shutdown'" "$ruby_logfile" 1
elif [ "$testname" == "server/chat.rb" ]
then
	fifo "say hello gamers" "$cl_fifo"
	sleep 1
	fifo "say uwu" "$cl_fifo"
	sleep 1
	fifo "rcon_auth test" "$cl_fifo"
	sleep 1
	fifo "rcon shutdown" "$cl_fifo"
	sleep 1
	fifo "quit" "$cl_fifo"
	# ddnet quitting can get stuck so send a kill to ensure it dies
	kill "$_client_pid"

	sleep 1 # wait for logfiles to be written

	assert_in_log "hello gamers" "$ruby_logfile" 1
	assert_in_log "[testchat] test_client: uwu" "$ruby_logfile" 1
else
	echo "Error: unkown test '$testname'"
	exit 1
fi

echo "[*] waiting for jobs to finish ..."
while true
do
	running_jobs="$(jobs | grep -v timeout)"
	if [ "$running_jobs" == "" ]
	then
		break
	fi
	echo "[*] waiting for:"
	echo "$running_jobs"
	sleep 1
done

if [ -f "$tmpdir/timeout.txt" ]
then
	echo "[-] Error timeouted"
	exit 1
fi

echo "[+] Test passed"

