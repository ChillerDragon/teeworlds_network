#!/bin/bash

if [ ! -d spec ]
then
	echo "Error: spec folder not found"
	echo "       run this script from the root of repo"
	exit 1
fi

function missing_unit_tests() {
	local ruby_file
	local got_err=0
	while read -r ruby_file
	do
		ruby_file="${ruby_file::-3}"
		if ! grep -rq "$ruby_file" spec/
		then
			echo "[-] Error: missing unit tests for $ruby_file.rb"
			got_err=1
		fi
	done < <(find lib/ -name "*.rb")
	if [ "$got_err" == "0" ]
	then
		echo "[+] OK: every file has a unit test."
		return 1
	else
		echo "[-] Error: missing unit tests."
		return 0
	fi
}

if missing_unit_tests
then
	exit 1
fi

