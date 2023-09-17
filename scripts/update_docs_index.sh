#!/bin/bash

if [ ! -d spec ]
then
	echo "Error: spec folder not found"
	echo "       run this script from the root of repo"
	exit 1
fi

tmpdir=scripts/tmp
mkdir -p scripts/tmp

arg_generate_docs=0

for arg in "$@"
do
	if [ "$arg" == "--fix" ] || [ "$arg" == "--generate-docs" ]
	then
		arg_generate_docs=1
	else
		echo "usage: ./scripts/update_docs_index.sh [--fix]"
		exit 1
	fi
done

function print_hooks() {
	local version="$1"
	local hook
	local hook_slug
	while read -r hook
	do
		hook_slug="${hook%%(*}"
		echo ""
		echo "[#$hook](classes/TeeworldsClient.md#$hook_slug)"
	done < <(grep '###' "docs/$version/classes/TeeworldsClient.md" | cut -d'#' -f5)
}

function gen_doc_index() {
	local version="$1"
	local index_file="docs/$version/README.md"
	if [ ! -f "$index_file" ]
	then
		echo "Error: missing index file $index_file"
		exit 1
	fi
	local tmpfile="$tmpdir/README.md"
	{
		awk '1;/TeeworldsClient/{exit}' "$index_file"
		print_hooks "$version"
	} > "$tmpfile"
	if [ "$arg_generate_docs" == "1" ]
	then
		mv "$tmpfile" "$index_file"
		return
	fi
	local diff
	if ! diff="$(diff "$tmpfile" "$index_file")"
	then
		echo "Error: failed to check diff"
		exit 1
	fi
	if [ "$diff" != "" ]
	then
		echo "Error: documentation index is not up to date"
		echo "       to fix this run ./scripts/update_docs_index.sh --fix"
		echo ""
		echo "$diff"
		exit 1
	fi
}

function main() {
	local version
	version="$(grep TEEWORLDS_NETWORK_VERSION lib/version.rb | cut -d"'" -f2)"
	if [ "$version" == "" ]
	then
		echo "Error: failed to get library version"
		exit 1
	fi
	gen_doc_index "$version"
}

main
