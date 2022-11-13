#!/bin/bash

if [ ! -d spec ]
then
	echo "Error: spec folder not found"
	echo "       run this script from the root of repo"
	exit 1
fi

tmpdir=scripts/tmp
mkdir -p scripts/tmp

function get_hooks() {
	local ruby_file="$1"
	grep -o "^[[:space:]]*def on_.*(&block)" "$ruby_file" | grep -o "on_[^(]*" | awk NF
}

function check_file() {
	local ruby_class="$1"
	local ruby_file="$2"
	local hooks
	local hook
	local version
	local got_err=0
	version="$(grep TEEWORLDS_NETWORK_VERSION lib/version.rb | cut -d"'" -f2)"
	hooks="$(get_hooks "$ruby_file")"
	if [ "$version" == "" ]
	then
		echo "Error: failed to get library version"
		exit 1
	fi

	# self testing the test
	# if the test finds no hooks the test is wrong not the code
	if [ "$(echo "$hooks" | wc -l)" -lt 8 ]
	then
		echo "Error: found only $(echo "$hooks" | wc -l) hooks in $ruby_file"
		echo "       expected 8 or more"
		exit 1
	fi

	for hook in $hooks
	do
		local hook_err=0
		echo -n "[*] checking hook: $hook"
		# check documentation
		local mdfile
		mdfile="docs/$version.md"
		if [ ! -f "$mdfile" ]
		then
			echo "Error: documentation not found $mdfile"
			exit 1
		fi
		if ! grep -q "#$hook" "$mdfile"
		then
			echo " ERROR: missing documentation in $mdfile"
			got_err=1
			hook_err=1
		else
			printf ' .'
		fi

		# check calling it
		local tmpfile
		tmpfile="$tmpdir/hook.rb"
		{
			echo '# frozen_string_literal: true'
			echo ''
			echo "require_relative '../../$ruby_file'"
			echo "obj = $ruby_class.new"
			echo "obj.$hook { |_| _ }"
		} > "$tmpfile"
		if ! ruby "$tmpfile" &>/dev/null
		then
			echo " ERROR: calling the hook failed"
			ruby "$tmpfile"
		elif [ "$hook_err" == "0" ]
		then
			echo ". OK"
		fi
	done
	if [ "$got_err" == "0" ]
	then
		echo "[+] OK: all hooks okay."
		return 1
	else
		echo "[-] Error: some hooks have errors."
		return 0
	fi
}

check_file TeeworldsClient lib/teeworlds_client.rb
# check_file TeeworldsServer lib/teeworlds_server.rb

