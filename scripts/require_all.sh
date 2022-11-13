#!/bin/bash

if [ ! -d spec ]
then
	echo "Error: spec folder not found"
	echo "       run this script from the root of repo"
	exit 1
fi

tmpdir=scripts/tmp
mkdir -p scripts/tmp
tmpfile="$tmpdir/require_all.rb"
{
	echo '# frozen_string_literal: true'
	echo ''
} > "$tmpfile"

function require_all() {
	local ruby_file
	while read -r ruby_file
	do
		ruby_file="${ruby_file::-3}"
		echo "require_relative '../../$ruby_file'" >> "$tmpfile"
	done < <(find lib/ -name "*.rb")
	if ruby "$tmpfile"
	then
		echo "[+] OK: no file crashed when being run."
		return 1
	else
		echo "[-] Error: loading all files crashed"
		return 0
	fi
}

if require_all
then
	exit 1
fi

